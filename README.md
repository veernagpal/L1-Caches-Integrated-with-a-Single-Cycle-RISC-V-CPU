# L1-Caches-Integrated-with-a-Single-Cycle-RISC-V-CPU
Three L1 Cache Architectures Integrated with a RISC-V CPU - Direct-Mapped, Fully Associative, and 2-Way Set-Associative L1 Data Cache Implementations

This project implements and verifies three L1 data cache architectures integrated with a single-cycle RISC-V CPU. The cache designs include direct-mapped, fully associative, and 2-way set-associative organizations, each using write-back, write-allocate, dirty eviction handling, and 128-bit block transfers.

Motivation For this Project :
Modern processors operate much faster than main memory, making memory latency a major performance bottleneck. Cache memories reduce this gap by storing recently accessed data closer to the CPU.
This project explores how different L1 data cache organizations affect processor-memory interaction when integrated with a simple RISC-V single-cycle core. The goal is to understand and compare direct-mapped, fully associative, and set-associative cache designs in terms of hit/miss behavior, replacement policy, write-back handling, hardware complexity, performance, average memory access time, and understand the tradeoff between speed, area, and complexity between the different cache mapping methodologies.

The system consists of a single-cycle RISC-V CPU connected to an L1 data cache, which interfaces with a simulated high-latency main memory. The CPU issues load and store requests to the cache. On a cache hit, data is served directly from the cache. On a miss, the cache fetches a 128-bit block from main memory and stalls the CPU until the access is complete.

Three cache organizations were implemented separately and integrated with the same CPU and memory subsystem:

      - Direct-Mapped L1 Cache
      - Fully Associative L1 Cache with LRU replacement
      - 2-Way Set-Associative L1 Cache with per-set LRU replacement

  

