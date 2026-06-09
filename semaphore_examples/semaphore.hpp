#pragma once

#include <condition_variable>
#include <mutex>

class Semaphore {
public:
    explicit Semaphore(int initial_count) : count_(initial_count) {}

    void P() {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_.wait(lock, [this] { return count_ > 0; });
        --count_;
    }

    void V() {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            ++count_;
        }
        cv_.notify_one();
    }

private:
    int count_;
    std::mutex mutex_;
    std::condition_variable cv_;
};
