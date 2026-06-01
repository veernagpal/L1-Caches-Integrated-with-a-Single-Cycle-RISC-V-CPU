# L1-Caches-Integrated-with-a-Single-Cycle-RISC-V-CPU
Three L1 Cache Architectures Integrated with a RISC-V CPU - Direct-Mapped, Fully Associative, and 2-Way Set-Associative L1 Data Cache Implementations

This project implements and verifies three L1 data cache architectures integrated with a single-cycle RISC-V CPU. The cache designs include direct-mapped, fully associative, and 2-way set-associative organizations, each using write-back, write-allocate, dirty eviction handling, and 128-bit block transfers.

Motivation For this Project :
Modern processors operate much faster than main memory, making memory latency a major performance bottleneck. Cache memories reduce this gap by storing recently accessed data closer to the CPU.
This project explores how different L1 data cache organizations affect processor-memory interaction when integrated with a simple RISC-V single-cycle core. The goal is to understand and compare direct-mapped, fully associative, and set-associative cache designs in terms of hit/miss behavior, replacement policy, write-back handling, hardware complexity, performance, average memory access time, and understand the tradeoff between speed, area, and complexity between the different cache mapping methodologies.

The system consists of a single-cycle RISC-V CPU connected to an L1 data cache, which interfaces with a simulated high-latency main memory. The CPU issues load and store requests to the cache. On a cache hit, data is served directly from the cache. On a miss, the cache fetches a 128-bit block from main memory and stalls the CPU until the access is complete.

RISC-V CPU → L1 Data Cache → 128-bit Block Data Memory

Three cache organizations were implemented separately and integrated with the same CPU and memory subsystem:

      - Direct-Mapped L1 Cache
      - Fully Associative L1 Cache with LRU replacement
      - 2-Way Set-Associative L1 Cache with per-set LRU replacement

All three cache designs use the same CPU-memory interface and support the following features:

      - 32-bit load/store interface between the CPU and cache.
      - 128-bit block transfers between the cache and main memory (i.e block size = 16 bytes = 4 words).
      - Write-back policy, where memory is updated only when a dirty block is evicted.
      - Write-allocate policy, where store misses first bring the block into cache.
      - Dirty bits to track modified cache lines.
      - CPU stalling using `mem_wait` signal while the cache handles misses.
      - Hit and miss counters to compare cache behavior.
      - Directed RISC-V load/store tests to verify hits, misses, stores, evictions, writebacks and replacement behavior  
1. Direct-Mapped L1 Cache
The direct-mapped cache is the simplest cache design in this project. Each memory block has only one possible place in the cache, decided by the index bits of the address.

For this implementation, the cache has 8 lines and each line stores 4 words.

Cache size = 8 lines × 4 words × 4 bytes = 128 bytes  
Block size = 4 words = 16 bytes  

The address is split like this : | Tag | Index | Word Offset | Byte Offset |

For this cache:

     - Word offset = address[3:2]
     - Index = address[6:4]
     - Tag = address[31:7]

The mapping is done using: 

      Cache line index = Memory block number mod Number of cache lines

Since there are 8 cache lines:

      Cache line index = Memory block number mod 8

And:

      Memory block number = Address / 16

Example:

      For address 0x00000080:
      
      Memory block number = 0x80 / 16  
      Memory block number = 128 / 16 = 8  
      
      Cache line index = 8 mod 8 = 0
      
      So address 0x00000080 maps to cache line 0.
      
      Similarly:
      
      - Address 0x00000000 maps to block 0, cache line 0.
      - Address 0x00000080 maps to block 8, cache line 0.

This means block 0 and block 8 both map to the same cache line. If block 0 is already present and block 8 is accessed, block 0 has to be replaced. This is why direct-mapped caches can suffer from conflict misses.

The main advantage of this cache is that it is simple and fast to check, because only one cache line is looked up for each memory access.

In context of the hardware, the direct-mapped cache is the least complex of the three designs. For every memory access, the index bits directly select one cache line, and only that selected line is checked. Because of this, the direct-mapped cache needs only one tag comparator. The cache does not need any replacement policy logic because the replacement line is already fixed by the index. This makes the design simple in terms of area, control logic, and power consumption. Since only one cache line is accessed and only one tag comparison is performed per request, the hardware activity is lower compared to fully associative and set-associative caches. However, the tradeoff is that conflict misses are more likely. If two frequently used memory blocks map to the same cache line, they keep replacing each other even if other cache lines are empty.


 2. Fully Associative L1 Cache

The fully associative cache removes the fixed-line mapping used in the direct-mapped cache. In this design, a memory block can be placed in any cache line.

This helps reduce conflict misses because two blocks do not fight for one fixed line. However, the hardware becomes more complex because the cache has to compare the requested tag with the tags of all cache lines.

For this implementation, the cache has 8 lines and each line stores 4 words.
      
      Cache size = 8 lines × 4 words × 4 bytes = 128 bytes  
      Block size = 4 words = 16 bytes  

The address is split like this:

      | Tag | Word Offset | Byte Offset |

For this cache:

- Word offset = address[3:2]
- Tag = address[31:4]

There is no index field in a fully associative cache.

The mapping idea is: A memory block can be placed in any available cache line.

So instead of using an index to directly select one line, the cache searches all 8 lines and checks if any valid line has a matching tag.

Example:

For address 0x00000080:

      Memory block number = 0x80 / 16  
      Memory block number = 128 / 16 = 8  

In the direct-mapped cache, block 8 maps only to cache line 0.  
In the fully associative cache, block 8 can be placed in any cache line.

This means block 0 and block 8 can both stay in the cache at the same time, as long as there are free cache lines available.

When the cache is full, a replacement policy is needed. In this implementation, LRU replacement is used.

LRU (Least Recently Used) . The cache evicts the line that has not been used for the longest time.

Hardware-wise, this cache is more complex than the direct-mapped cache. It needs 8 tag comparators, one for each cache line. It also needs extra LRU tracking logic to decide which line should be replaced on a miss. The advantage is that it reduces conflict misses. The tradeoff is higher hardware cost, more comparison logic, and higher power consumption because multiple tags are checked during every cache access.

3. 2-Way Set-Associative L1 Cache

The 2-way set-associative cache is a middle ground between the direct-mapped and fully associative designs. Instead of mapping a memory block to only one fixed cache line, the cache is divided into sets, and each set has two possible ways where a block can be placed.

In this implementation, the cache has 4 sets and 2 ways per set. Each cache line stores 4 words.

Cache size = 4 sets × 2 ways × 4 words × 4 bytes = 128 bytes  
Block size = 4 words = 16 bytes  

The address is split like this:

      | Tag | Set Index | Word Offset | Byte Offset |

For this cache:

      - Word offset = address[3:2]
      - Set index = address[5:4]
      - Tag = address[31:6]

The mapping is done using:

      Set index = Memory block number mod Number of sets

Since there are 4 sets:

      Set index = Memory block number mod 4

And:

      Memory block number = Address / 16

Example:

      For address 0x00000080:
      
      Memory block number = 0x80 / 16  
      Memory block number = 128 / 16 = 8  
      
      Set index = 8 mod 4 = 0
      
      So address 0x00000080 maps to set 0.

But since this is a 2-way set-associative cache, the block can be placed in either way 0 or way 1 inside set 0.

For example:
      
      - Address 0x00000000 maps to block 0, set 0.
      - Address 0x00000080 maps to block 8, set 0.

Both blocks map to the same set, but they can stay in the cache together because set 0 has two ways. This reduces conflict misses compared to the direct-mapped cache.

A 1-bit LRU policy is used for each set. This bit keeps track of which way should be replaced next when both ways in a set are full.

In hardware, the 2-way set-associative cache is more complex than the direct-mapped cache but simpler than the fully associative cache.
For each access, the set index selects one set. Inside that set, both ways are checked in parallel using two tag comparators. If either way has a matching valid tag, it is a cache hit. This cache uses 2 tag comparators per access, compared to 1 comparator in the direct-mapped cache and 8 comparators in the fully associative cache. The replacement logic is also simpler than the fully associative cache. Since there are only two ways per set, one LRU bit per set is enough to decide which way should be evicted. This mapping gives a good balance between hardware cost and cache performance. It reduces many conflict misses while avoiding the higher area and power overhead of a fully associative cache.

Cache Controller FSM

Each cache uses a finite state machine to control the flow of a CPU memory request. The FSM handles cache hits, cache misses, memory reads, dirty writebacks, cache updates, and CPU stalling.

The main states used are:

      - IDLE  
        The cache waits for a load or store request from the CPU.

      - TAG_CHECK  
        The cache checks whether the requested block is already present.  
        In the direct-mapped cache, one selected line is checked.  
        In the fully associative cache, all lines are checked.  
        In the 2-way set-associative cache, both ways of the selected set are checked.

      - WRITEBACK  
        If the selected victim block is dirty, it is written back to main memory before being replaced.
      
      - FILL  
        The required 128-bit block is fetched from main memory and stored into the cache.
      
      - UPDATE  
        The original CPU request is completed.  
        For a load, the requested word is forwarded to the CPU.  
        For a store, the cache line is updated and marked dirty.
      
      - DONE  
        The cache releases `mem_wait`, allowing the CPU to continue to the next instruction.

Cache transitions for different cases:

Cache hit:

      IDLE → TAG_CHECK → UPDATE → DONE

Clean miss:

      IDLE → TAG_CHECK → FILL → UPDATE → DONE

Dirty miss:

      IDLE → TAG_CHECK → WRITEBACK → FILL → UPDATE → DONE
