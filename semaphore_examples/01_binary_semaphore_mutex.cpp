#include <chrono>
#include <iostream>
#include <thread>
#include <vector>

#include "semaphore.hpp"

Semaphore mutex_sem(1);
int shared_counter = 0;

void worker(int id) {
    for (int i = 0; i < 10000; ++i) {
        mutex_sem.P();
        ++shared_counter;
        mutex_sem.V();
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

    std::cout << "expected counter = 40000\n";
    std::cout << "actual counter   = " << shared_counter << '\n';
    return 0;
}
