#include <vector>
#include <climits>
#include <iostream>
#include <utility>

template<typename k, typename v>
class pq_t {
    std::vector<std::pair<k, v>> data = {};

public:
    bool empty() const { return data.empty(); }

    void insert(const k &key, const v &val)
    {
        size_t ix = data.size();
        data.emplace_back(key, val);
        size_t parent_ix = (ix - 1) / 2;
        while (ix > 0 && data[ix].first < data[parent_ix].first)
        {
            std::swap(data[ix], data[parent_ix]);
            ix = parent_ix;
            parent_ix = (ix - 1) / 2;
        }
    }

    v extract_min()
    {
        std::swap(data.front(), data.back());
        v res = data.back().second;
        data.pop_back();
        size_t ix = 0;
        size_t left_child = 2 * ix + 1;
        size_t right_child = 2 * ix + 2;
        while (true)
        {
            if (right_child < data.size())
            {
                if (data[right_child].first < data[ix].first)
                {
                    if (data[right_child] < data[left_child])
                    {
                        std::swap(data[ix], data[right_child]);
                        ix = right_child;
                        goto next;
                    }
                }
                goto check_left;
            }
            else if (left_child < data.size())
            {
check_left:
                if (data[left_child].first < data[ix].first)
                {
                    std::swap(data[ix], data[left_child]);
                    ix = left_child;
                }
                else
                    break;
            }
            else
                break;

next:
            left_child = 2 * ix + 1;
            right_child = 2 * ix + 2;
        }
        return res;
    }
};

int main(void)
{
    std::vector<std::vector<char>> input;
    std::string line;
    while (std::getline(std::cin, line))
    {
        input.emplace_back();
        for (char c : line)
            input.back().emplace_back(c - '0');
    }

    std::vector<std::vector<char>> risk;
    for (size_t i = 0; i < 5; ++i)
    {
        for (auto &l : input)
        {
            risk.emplace_back();
            for (size_t j = 0; j < 5; ++j)
                for (auto c : l)
                    risk.back().push_back((c - 1 + i + j) % 9 + 1);
        }
    }

    const size_t start_x = 0, start_y = 0, end_x = risk.size() - 1, end_y = risk.front().size() - 1;

    std::vector<std::vector<unsigned int>> dist(risk.size());
    for (auto &vec : dist)
        vec.resize(risk.front().size(), UINT_MAX);
    std::vector<std::vector<bool>> visited(risk.size());
    for (auto &vec : visited)
        vec.resize(risk.front().size());
    dist[start_x][start_y] = 0;
    pq_t<unsigned int, std::pair<size_t, size_t>> pq;
    pq.insert(0, { start_x, start_y });

    while (!pq.empty())
    {
        auto [x, y] = pq.extract_min();
        if (visited[x][y])
            continue;
        if (x == end_x && y == end_y)
            break;

        visited[x][y] = true;
        if (x > 1 && dist[x][y] + risk[x - 1][y] < dist[x - 1][y])
        {
            dist[x - 1][y] = dist[x][y] + risk[x - 1][y];
            pq.insert(dist[x - 1][y], { x - 1, y });
        }
        if (x + 1 < risk.size() && dist[x][y] + risk[x + 1][y] < dist[x + 1][y])
        {
            dist[x + 1][y] = dist[x][y] + risk[x + 1][y];
            pq.insert(dist[x + 1][y], { x + 1, y });
        }
        if (y > 1 && dist[x][y] + risk[x][y - 1] < dist[x][y - 1])
        {
            dist[x][y - 1] = dist[x][y] + risk[x][y - 1];
            pq.insert(dist[x][y - 1], { x, y - 1 });
        }
        if (y + 1 < risk.front().size() && dist[x][y] + risk[x][y + 1] < dist[x][y + 1])
        {
            dist[x][y + 1] = dist[x][y] + risk[x][y + 1];
            pq.insert(dist[x][y + 1], { x, y + 1 });
        }
    }
    std::cout << dist[end_x][end_y] << std::endl;
}
