#!/usr/bin/env node

const yargs = require("yargs");
const { hideBin } = require("yargs/helpers");
const https = require("https");

// Seed Data
let seeds = [
    { id: 100, t: 71.2, h: 35.1, c: 0.5, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.02] },
    { id: 101, t: 71.8, h: 34.9, c: 0.5, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.02] },
    { id: 102, t: 72.0, h: 34.9, c: 0.5, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.02] },
    { id: 103, t: 71.3, h: 35.2, c: 0.4, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.02] },
    { id: 200, t: 73.6, h: 35.8, c: 0.5, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.05] },
    { id: 201, t: 74.0, h: 35.2, c: 0.5, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.02] },
    { id: 202, t: 75.3, h: 35.7, c: 0.5, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.02] },
    { id: 203, t: 74.8, h: 35.9, c: 0.4, t_inc: [-0.05, 0.05], h_inc: [-0.05, 0.05], c_inc: [-0.02, 0.02] },
];

function randomInRange(range) {
    const [min, max] = range;
    return Math.random() * (max - min) + min;
}

function incrementData(data) {
    data.t += randomInRange(data.t_inc);
    data.h += randomInRange(data.h_inc);
    data.c += randomInRange(data.c_inc);

    // Avoid negative values
    data.h = Math.max(0, data.h);
    data.c = Math.max(0, data.c);

    return data;
}

function lineProtocolBatch(pointData, offset) {
    const batch = [];
    const now = (Date.now() - ((60 * 60 * 1000) - (10 * offset * 1000))) * 1e6;

    pointData.forEach((v) => {
        batch.push(`airSensors,sensor_id=TLM0${v.id} temperature=${v.t},humidity=${v.h},co=${v.c} ${now}`);
    });

    return batch.join("\n");
}

function sendBatches(dataset) {
    for (let i = 0; i <= 660; i++) {
        dataset = dataset.map((seed) => incrementData(seed));
        console.log(lineProtocolBatch(dataset, i));
    }
}

// Handle command-line arguments
yargs(hideBin(process.argv))
    .scriptName("air-sensor-data")
    .usage("Usage: $0 [OPTIONS]")
    .help("help")
    .alias("help", "h")
    .parse();

// Run the data stream
try {
    sendBatches(seeds);
} catch (err) {
    console.error("\nStopping data stream...", err);
}