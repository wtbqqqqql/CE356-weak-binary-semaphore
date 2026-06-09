#include <iostream>
#include <thread>
#include <vector>

int shared_counter = 0;

void worker(int id) {
    for (int i = 0; i < 100000; ++i) {
        ++shared_counter;
    }
    std::cout << "worker " << id << " finished\n";
}

int main() {
    std::vector<std::thread> threads;

    for (int i = 0; i < 4; ++i) {
        threads.emplace_back(worker, i);
    }

    for (auto& t : threads) {
        t.join();
    }

    std::cout << "expected counter = 400000\n";
    std::cout << "actual counter   = " << shared_counter << '\n';
    return 0;
}
