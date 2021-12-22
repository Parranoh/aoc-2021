#include <vector>
#include <iostream>
#include <sstream>
#include <algorithm>
#include <set>

typedef struct {
    int x, y, z;
} point_t;

bool operator<(point_t p, point_t q)
{
    return p.x < q.x || (p.x == q.x && (p.y < q.y || (p.y == q.y && p.z < q.z)));
}

bool operator==(point_t p, point_t q)
{
    return p.x == q.x && p.y == q.y && p.z == q.z;
}

typedef struct {
    int tx, ty, tz;
    unsigned char rot;
} transrot_t;

point_t transrot(const transrot_t &t, const point_t &p)
{
    point_t q;
    switch (t.rot)/*{{{*/
    {
        case  0: q = {  p.x,  p.y,  p.z }; break;
        case  1: q = { -p.x, -p.y,  p.z }; break;
        case  2: q = { -p.x,  p.y, -p.z }; break;
        case  3: q = {  p.x, -p.y, -p.z }; break;

        case  4: q = {  p.y,  p.z,  p.x }; break;
        case  5: q = { -p.y, -p.z,  p.x }; break;
        case  6: q = { -p.y,  p.z, -p.x }; break;
        case  7: q = {  p.y, -p.z, -p.x }; break;

        case  8: q = {  p.z,  p.x,  p.y }; break;
        case  9: q = { -p.z, -p.x,  p.y }; break;
        case 10: q = { -p.z,  p.x, -p.y }; break;
        case 11: q = {  p.z, -p.x, -p.y }; break;

        case 12: q = { -p.z,  p.y,  p.x }; break;
        case 13: q = {  p.z, -p.y,  p.x }; break;
        case 14: q = {  p.z,  p.y, -p.x }; break;
        case 15: q = { -p.z, -p.y, -p.x }; break;

        case 16: q = { -p.y,  p.x,  p.z }; break;
        case 17: q = {  p.y, -p.x,  p.z }; break;
        case 18: q = {  p.y,  p.x, -p.z }; break;
        case 19: q = { -p.y, -p.x, -p.z }; break;

        case 20: q = { -p.x,  p.z,  p.y }; break;
        case 21: q = {  p.x, -p.z,  p.y }; break;
        case 22: q = {  p.x,  p.z, -p.y }; break;
        case 23: q = { -p.x, -p.z, -p.y }; break;
    }/*}}}*/
    q.x += t.tx;
    q.y += t.ty;
    q.z += t.tz;
    return q;
}

int main(void)
{
    std::vector<std::vector<point_t>> rel_beacons;
    std::vector<std::vector<point_t>> abs_beacons;
    std::vector<bool> found;
    std::string line;
    while (std::getline(std::cin, line))
    {
        rel_beacons.emplace_back();
        abs_beacons.emplace_back();
        found.push_back(false);
        while (std::getline(std::cin, line))
        {
            if (line.empty())
                break;
            point_t p;
            char c;
            std::istringstream ss(line);
            ss >> p.x >> c >> p.y >> c >> p.z;
            rel_beacons.back().push_back(p);
        }
    }

    found[0] = true;
    abs_beacons[0] = rel_beacons[0];
    std::vector<point_t> scanners;

loop:
    for (size_t i = 0; i < found.size(); ++i)
        if (!found[i])
            // try to find scanner i
            for (unsigned char rot = 0; rot < 24; ++rot)
            {
                // with rotation rot
                std::vector<point_t> rot_beacons;
                for (const auto &p : rel_beacons[i])
                    rot_beacons.push_back(transrot({ 0, 0, 0, rot }, p));
                for (size_t j = 0; j < found.size(); ++j)
                    if (found[j])
                    {
                        // relative to scanner j
                        std::vector<point_t> offsets;
                        for (const auto &p : rot_beacons)
                            for (const auto &q : abs_beacons[j])
                                offsets.push_back({ q.x - p.x, q.y - p.y, q.z - p.z });
                        std::sort(offsets.begin(), offsets.end());
                        for (size_t n = 11; n < offsets.size(); ++n)
                            if (offsets[n - 11] == offsets[n])
                            {
                                scanners.push_back(offsets[n]);
                                for (const auto &p : rot_beacons)
                                    abs_beacons[i].push_back(transrot({ offsets[n].x, offsets[n].y, offsets[n].z, 0 }, p));
                                found[i] = true;
                                goto loop;
                            }
                    }
            }

    int max_dist = 0;
    for (const auto &s : scanners)
        for (const auto &t : scanners)
            max_dist = std::max(max_dist, abs(s.x - t.x) + abs(s.y - t.y) + abs(s.z - t.z));

    std::cout << max_dist << std::endl;

    return 0;
}
