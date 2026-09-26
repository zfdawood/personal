pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU + memory load, sampled from /proc on a timer. Exposed as 0.0–1.0 fractions
// so the bar meters can bind directly to them.
Singleton {
    id: root

    property real cpu: 0.0    // 0.0–1.0 busy fraction over the last interval
    property real mem: 0.0    // 0.0–1.0 used fraction

    // ── CPU: delta of busy vs total jiffies between two /proc/stat samples ──
    property double _prevTotal: 0
    property double _prevIdle: 0

    function _sampleCpu(text) {
        // First line: "cpu  user nice system idle iowait irq softirq steal ..."
        const line = text.split("\n")[0];
        // guest/guest_nice (fields 9-10) are already counted in user/nice, so
        // stop at steal to avoid double-counting VM time.
        const parts = line.trim().split(/\s+/).slice(1, 9).map(Number);
        if (parts.length < 5)
            return;
        const idle = parts[3] + (parts[4] || 0);        // idle + iowait
        let total = 0;
        for (const p of parts)
            total += p;
        const dTotal = total - root._prevTotal;
        const dIdle = idle - root._prevIdle;
        // First sample has no baseline (it would be the since-boot average).
        if (root._prevTotal > 0 && dTotal > 0)
            root.cpu = Math.max(0, Math.min(1, (dTotal - dIdle) / dTotal));
        root._prevTotal = total;
        root._prevIdle = idle;
    }

    function _sampleMem(text) {
        let total = 0, avail = 0;
        for (const l of text.split("\n")) {
            if (l.startsWith("MemTotal:"))
                total = Number(l.replace(/[^0-9]/g, ""));
            else if (l.startsWith("MemAvailable:"))
                avail = Number(l.replace(/[^0-9]/g, ""));
        }
        if (total > 0)
            root.mem = Math.max(0, Math.min(1, (total - avail) / total));
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root._sampleCpu(text())
    }
    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: root._sampleMem(text())
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }
}
