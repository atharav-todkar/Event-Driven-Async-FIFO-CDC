## 📌 Problem Statement

Modern digital systems often operate across multiple clock domains. Transferring data reliably between these domains is a critical challenge due to timing mismatches and metastability issues.

This project focuses on designing an **event-driven asynchronous FIFO** to ensure safe and efficient data transfer across independent clock domains.

---

## ⚠️ Why Clock Domain Crossing (CDC) is Important

Clock Domain Crossing (CDC) occurs when data moves between circuits operating on different clock signals.

Improper CDC design can lead to:

* Metastability
* Data corruption
* System-level failures

Ensuring reliable CDC is essential in:

* High-speed processors
* Communication systems
* FPGA/ASIC designs

---

## 🚀 Why Asynchronous FIFO?

An Asynchronous FIFO is a widely used solution for CDC problems because:

* It allows independent read/write clocks
* Uses Gray code to reduce synchronization errors
* Provides safe buffering between clock domains

This project enhances the traditional FIFO by adding:

* Event-driven monitoring
* CDC stress analysis under random conditions
