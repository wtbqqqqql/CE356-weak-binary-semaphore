#include <chrono>
#include <iostream>
#include <thread>
#include <vector>

#include "semaphore.hpp"

constexpr int kBufferSize = 3;
constexpr int kItemsPerProducer = 5;

int buffer[kBufferSize];
int in_index = 0;
int out_index = 0;

Semaphore spaces(kBufferSize);
Semaphore items(0);
Semaphore in_mutex(1);
Semaphore out_mutex(1);

void produce_one(int producer_id, int value) {
    spaces.P();

    in_mutex.P();
    buffer[in_index] = value;
    std::cout << "[producer " << producer_id << "] put " << value
              << " at slot " << in_index << '\n';
    in_index = (in_index + 1) % kBufferSize;
    in_mutex.V();

    items.V();
}

int consume_one(int consumer_id) {
    items.P();

    out_mutex.P();
    int value = buffer[out_index];
    std::cout << "[consumer " << consumer_id << "] got " << value
              << " from slot " << out_index << '\n';
    out_index = (out_index + 1) % kBufferSize;
    out_mutex.V();

    spaces.V();
    return value;
}

void producer(int producer_id, int start_value) {
    for (int i = 0; i < kItemsPerProducer; ++i) {
        std::this_thread::sleep_for(std::chrono::milliseconds(150));
        produce_one(producer_id, start_value + i);
    }
}

void consumer(int consumer_id, int total_items) {
    for (int i = 0; i < total_items; ++i) {
        std::this_thread::sleep_for(std::chrono::milliseconds(220));
        consume_one(consumer_id);
    }
}

int main() {
    std::thread p1(producer, 1, 100);
    std::thread p2(producer, 2, 200);
    std::thread c1(consumer, 1, 5);
    std::thread c2(consumer, 2, 5);

    p1.join();
    p2.join();
    c1.join();
    c2.join();

    std::cout << "bounded buffer demo finished\n";
    return 0;
}
