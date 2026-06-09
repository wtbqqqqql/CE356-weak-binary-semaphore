#include <chrono>
#include <iostream>
#include <queue>
#include <thread>

#include "semaphore.hpp"

Semaphore items_ready(0);
std::queue<int> packet_queue;
std::mutex queue_mutex;

void receiver() {
    for (int packet = 1; packet <= 5; ++packet) {
        std::this_thread::sleep_for(std::chrono::milliseconds(300));

        {
            std::lock_guard<std::mutex> lock(queue_mutex);
            packet_queue.push(packet);
            std::cout << "[receiver] packet " << packet << " arrived\n";
        }

        items_ready.V();
    }
}

void printer() {
    for (int i = 0; i < 5; ++i) {
        items_ready.P();

        int packet = -1;
        {
            std::lock_guard<std::mutex> lock(queue_mutex);
            packet = packet_queue.front();
            packet_queue.pop();
        }

        std::cout << "[printer ] printing packet " << packet << '\n';
    }
}

int main() {
    std::thread t1(receiver);
    std::thread t2(printer);

    t1.join();
    t2.join();

    std::cout << "all packets processed\n";
    return 0;
}
