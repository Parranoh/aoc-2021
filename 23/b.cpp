#include <iostream>
#include <vector>
#include <array>
#include <map>
#include <queue>
#include <algorithm>

#define NUM_ROOMS 4
#define HALLWAY_LENGTH 7
#define HALLWAY_OFFSET 2
#define ROOM_SIZE 4

struct state_t {
    std::array<std::vector<char>, NUM_ROOMS> rooms;
    std::array<char, HALLWAY_LENGTH> hallway;
    bool operator<(const state_t &other) const { return rooms < other.rooms || rooms == other.rooms && hallway < other.hallway; }
    bool operator==(const state_t &other) const { return rooms == other.rooms && hallway == other.hallway; }
};

template<typename _K, typename _V>
struct pq_entry_t {
    _K key;
    _V val;
    pq_entry_t(const _K &k, const _V &v) : key(k), val(v) {}
    bool operator<(const pq_entry_t<_K, _V> &other) const { return key > other.key; }
};

template<typename _K, typename _V>
using pq_t = std::priority_queue<pq_entry_t<_K, _V>>;

int main(void)
{
    std::array<char, 16> str;
    std::cin.getline(&str[0], 16);
    std::cin.getline(&str[0], 16);
    std::cin.getline(&str[0], 16);
    char at = str[3], bt = str[5], ct = str[7], dt = str[9];
    std::cin.getline(&str[0], 16);
    char ab = str[3], bb = str[5], cb = str[7], db = str[9];

    const state_t init = { { std::vector { ab, 'D', 'D', at }, { bb, 'B', 'C', bt }, { cb, 'A', 'B', ct }, { db, 'C', 'A', dt } }, { '\0' } };
    const state_t target = { { std::vector { 'A', 'A', 'A', 'A' }, { 'B', 'B', 'B', 'B' }, { 'C', 'C', 'C', 'C' }, { 'D', 'D', 'D', 'D' } }, { '\0' } };
    const char *native = "ABCD";
    const auto cost = [](char c) -> unsigned int
    {
        unsigned int res = 1;
        for (char i = 'A'; i < c; ++i)
            res *= 10;
        return res;
    };

    std::map<state_t, unsigned int> dist;
    dist[init] = 0;
    pq_t<unsigned int, state_t> pq;
    pq.emplace(0, init);
    while (!pq.empty())
    {
        const auto d_v = pq.top().key;
        const auto v = pq.top().val;
        if (v == target)
            break;
        pq.pop();
        if (d_v > dist[v])
            // do not relax edges twice due to multiply inserted vertices
            continue;

        const auto relax = [&](char moving, unsigned int path_length, const state_t &w) -> void
        {
            const unsigned int d_w = d_v + cost(moving) * path_length;
            auto [it, inserted] = dist.emplace(w, d_w);
            if (inserted)
                pq.emplace(d_w, w);
            else if (d_w < it->second)
            {
                it->second = d_w;
                pq.emplace(d_w, w);
            }
        };

        // move out
        for (int r = 0; r < NUM_ROOMS; ++r)
        {
            const auto &room = v.rooms[r];
            if (room.empty() || std::all_of(room.cbegin(), room.cend(), [&](char c){ return c == native[r]; }))
                // cannot move out
                continue;

            for (int h = 0; h < HALLWAY_LENGTH; ++h)
            {
                for (int i = h; i < r + HALLWAY_OFFSET; ++i)
                    // go to left
                    if (v.hallway[i])
                        goto next_out;
                for (int i = r + HALLWAY_OFFSET; i <= h; ++i)
                    // go to right
                    if (v.hallway[i])
                        goto next_out;

                {
                    state_t w = v;
                    const unsigned int path_length = 2 *
                        (h < r + HALLWAY_OFFSET
                            ? r + HALLWAY_OFFSET - h
                            : h - r - HALLWAY_OFFSET + 1)
                        + ROOM_SIZE - w.rooms[r].size() - (h == 0 || h == HALLWAY_LENGTH - 1);
                    const char moving = w.rooms[r].back();
                    w.hallway[h] = moving;
                    w.rooms[r].pop_back();
                    relax(moving, path_length, w);
                }

next_out:
                {}
            }
        }

        // move in
        for (int h = 0; h < HALLWAY_LENGTH; ++h)
        {
            const char moving = v.hallway[h];
            if (!moving)
                continue;

            int r = moving - 'A';
            if (std::any_of(v.rooms[r].cbegin(), v.rooms[r].cend(), [&](char c){ return c != native[r]; }))
                // cannot move in
                continue;

            for (int i = h + 1; i < r + HALLWAY_OFFSET; ++i)
                // come from left
                if (v.hallway[i])
                    goto next_in;
            for (int i = r + HALLWAY_OFFSET; i < h; ++i)
                // come from right
                if (v.hallway[i])
                    goto next_in;

            {
                state_t w = v;
                w.hallway[h] = '\0';
                w.rooms[r].push_back(moving);
                const unsigned int path_length = 2 *
                    (h < r + HALLWAY_OFFSET
                        ? r + HALLWAY_OFFSET - h
                        : h - r - HALLWAY_OFFSET + 1)
                    + ROOM_SIZE - w.rooms[r].size() - (h == 0 || h == HALLWAY_LENGTH - 1);
                relax(moving, path_length, w);
            }

next_in:
            {}
        }
    }
    if (pq.empty())
        return EXIT_FAILURE;

    std::cout << pq.top().key << std::endl;
    return EXIT_SUCCESS;
}
