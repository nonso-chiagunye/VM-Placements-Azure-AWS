<h1 align="center">VM Placement Options on AWS and Azure</h1>

---

# [AWS](vm-placement-aws.sh)

---

## Cluster Placement Group (CPG):

This option optimizes performance and low-latency by placing VMs tightly close together (usually on the same hardware) within an Availability Zone. This is necessary for tightly-coupled node-to-node communication required for high-performance computing (HPC) and real-time analytics applications.

## Spread Placement Group (SPG):

Here, the emphasis is on fault tolerance and high availability. VMs are distributed across multiple distinct hardware racks, limiting the impact of single hardware failures. Ideal for application and database servers requiring high availability.

## Partition Placement Group (PPG):

Spreads your VMs across logical partitions, where groups of instances in one partition do not share the underlying hardware with groups of instances in different partitions. Each partition can span multiple AZs. Best for large-scale distributed and replicated applications, like Hadoop, Cassandra, and Kafka.

# [Azure](vm-placement-azure.ps1)

---
