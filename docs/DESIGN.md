# Design Architecture

## Overview

The asynchronous FIFO enables safe communication between two clock domains using synchronized Gray-coded pointers.

## Architecture Blocks

* Write Pointer Controller
* Read Pointer Controller
* FIFO Memory
* Gray Code Synchronizer

## Key Techniques

### 1. Gray Code Conversion

Binary pointers are converted to Gray code to ensure only one bit changes at a time.

### 2. Double Flip-Flop Synchronization

Each pointer crossing clock domain passes through two flip-flops to reduce metastability.

### 3. Full/Empty Detection

* FULL → when write pointer catches read pointer
* EMPTY → when read pointer equals write pointer

## Data Flow

Write Domain → Memory → Read Domain

## Diagram

<img width="1623" height="864" alt="Screenshot 2026-04-20 193241" src="https://github.com/user-attachments/assets/3dce2b34-48c3-4b2d-a114-ccbf4700404a" />
