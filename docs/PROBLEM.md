# Problem Statement: Asynchronous FIFO for CDC

## Background
Modern digital systems often operate across multiple clock domains. Direct data transfer between these domains can lead to metastability and data corruption.

## Problem
Design a FIFO that safely transfers data between two asynchronous clock domains without:
- Data loss
- Data corruption
- Metastability propagation

## Challenges
- Clock domain crossing (CDC)
- Pointer synchronization
- Reliable full/empty detection
- Handling underflow/overflow conditions

## Objective
Develop a robust asynchronous FIFO using:
- Gray code pointer synchronization
- Double flip-flop synchronizers
- Safe comparison logic

## Success Criteria
- No data mismatch under random traffic
- Correct full/empty flag behavior
- Stable operation under different clock frequencies
