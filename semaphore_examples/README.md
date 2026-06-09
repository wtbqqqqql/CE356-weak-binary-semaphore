# Semaphore Examples

These examples match the ideas in `referrence/05-synchronization.txt`:

- binary semaphore for mutual exclusion
- counting semaphore for event signaling
- bounded-buffer producer-consumer

## Build

```powershell
g++ -std=c++17 -pthread .\semaphore_examples\00_no_lock_race.cpp -o .\semaphore_examples\00_no_lock_race.exe
g++ -std=c++17 -pthread .\semaphore_examples\01_binary_semaphore_mutex.cpp -o .\semaphore_examples\01_binary_semaphore_mutex.exe
g++ -std=c++17 -pthread .\semaphore_examples\02_counting_semaphore_signal.cpp -o .\semaphore_examples\02_counting_semaphore_signal.exe
g++ -std=c++17 -pthread .\semaphore_examples\03_bounded_buffer.cpp -o .\semaphore_examples\03_bounded_buffer.exe
```

## Run

```powershell
.\semaphore_examples\00_no_lock_race.exe
.\semaphore_examples\01_binary_semaphore_mutex.exe
.\semaphore_examples\02_counting_semaphore_signal.exe
.\semaphore_examples\03_bounded_buffer.exe
```
