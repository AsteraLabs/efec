# efec
Enhanced low-latency FEC encoder and decoder for PCIe Flits

## Introduction
The standard PCIe FEC is a t=3, 3-way interleaved FEC. The enhanced FEC in this
repository implements three stronger flit protection schemes as follows:

| FEC           | Correction capability                                         | Flit Data Bytes | Flit CRC Bytes | Flit ECC Bytes |
| ------------- | ------------------------------------------------------------- | --------------- | -------------- | -------------- |
| Standard PCIe | t=3: Up to 3 symbols per Flit, one in each interleaved stream | 242             | 8              | 6              |
| eFEC mode 0   | t=3: Up to 3 symbols per Flit, any location                   | 242             | 8              | 6              |
| eFEC mode 1   | t=4: Up to 4 symbols per Flit, any location                   | 242             | 6              | 8              |
| eFEC mode 2   | t=5: Up to 5 symbols per Flit, any location                   | 242             | 4              | 10             |

## Flit Format

Flit byte layout for eFEC/CRC modes. "T3/T4/T5" denotes the ECC error-correction
capability (t = 3, 4, or 5 symbols). Each T-column pair covers CRC mode 0 (CRC-8
only) and CRC mode 1 (CRC-8 + CRC-32).

|               | Byte #     | T3     | T3     | T4     | T4     | T5     | T5     |
| ------------- | ---------- | ------ | ------ | ------ | ------ | ------ | ------ |
| eFEC mode     |            | 2'b00  | 2'b00  | 2'b01  | 2'b01  | 2'b1x  | 2'b1x  |
| CRC mode      |            | 0      | 1      | 0      | 1      | 0      | 1      |
| Flit byte loc | 255        | ECC    | ECC    | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 254        | ECC    | ECC    | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 253        | ECC    | ECC    | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 252        | ECC    | ECC    | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 251        | ECC    | ECC    | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 250        | ECC    | ECC    | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 249        | CRC8 7 | CRC8 7 | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 248        | CRC8 6 | CRC8 6 | ECC    | ECC    | ECC    | ECC    |
| Flit byte loc | 247        | CRC8 5 | CRC8 5 | CRC8 5 | CRC8 5 | ECC    | ECC    |
| Flit byte loc | 246        | CRC8 4 | CRC8 4 | CRC8 4 | CRC8 4 | ECC    | ECC    |
| Flit byte loc | 245        | CRC8 3 | CRC32  | CRC8 3 | CRC32  | CRC8 3 | CRC32  |
| Flit byte loc | 244        | CRC8 2 | CRC32  | CRC8 2 | CRC32  | CRC8 2 | CRC32  |
| Flit byte loc | 243        | CRC8 1 | CRC32  | CRC8 1 | CRC32  | CRC8 1 | CRC32  |
| Flit byte loc | 242        | CRC8 0 | CRC32  | CRC8 0 | CRC32  | CRC8 0 | CRC32  |
|               | 241 ... 0  | Data   | Data   | Data   | Data   | Data   | Data   |
