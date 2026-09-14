pragma Singleton

import QtQuick
import Quickshell

// Domain: pure audio grouping and labelling. Same nodes in -> same groups out.
// No I/O: nodes are opaque values whose public fields are read only to derive
// presentation. A sound card exposes one node per output/input (Speaker, HDMI
// 1-3, mics...) that all share `device.id`; this groups them back under the
// card so the UI shows one device with ports, not a flat list.
Singleton {
    function prop(node, key, fallback) {
        const p = node.properties;
        if (!p || p[key] === undefined || p[key] === "") return fallback;
        return String(p[key]);
    }

    function deviceId(node) {
        return prop(node, "device.id", "");
    }

    // Short, human port name ("Speaker", "HDMI 1", "Digital Microphone").
    function portLabel(node) {
        return node.nickname
            || prop(node, "device.profile.description", "")
            || node.description
            || node.name;
    }

    // The card name is carried in every node's full description; stripping the
    // node's own profile description leaves the shared device name.
    function deviceLabel(nodes) {
        if (nodes.length === 0) return "Audio";
        const first = nodes[0];
        const profile = prop(first, "device.profile.description", "");
        let label = first.description || "";
        if (profile !== "" && label.endsWith(profile))
            label = label.slice(0, label.length - profile.length);
        label = label.replace(/[-\u2013\s]+$/, "");
        if (label === "")
            label = prop(first, "api.alsa.card.name", "") || first.nickname || first.name;
        return label;
    }

    function deviceIcon(nodes) {
        if (nodes.length === 0) return Theme.iconVolume;
        const name = prop(nodes[0], "device.icon_name", "");
        if (name.indexOf("video") >= 0) return Theme.iconDisplay;
        if (name.indexOf("headset") >= 0 || name.indexOf("headphone") >= 0)
            return Theme.iconHeadphones;
        if (name.indexOf("bluetooth") >= 0) return Theme.iconBluetooth;
        if (name.indexOf("mic") >= 0) return Theme.iconMicrophone;
        return Theme.iconVolume;
    }

    function priority(node) {
        const n = parseInt(prop(node, "priority.session", "0"), 10);
        return isNaN(n) ? 0 : n;
    }

    function bestPriority(nodes) {
        let best = 0;
        for (const node of nodes) best = Math.max(best, priority(node));
        return best;
    }

    function sortNodes(nodes) {
        return nodes.slice().sort((a, b) =>
            (priority(b) - priority(a)) || String(a.name).localeCompare(String(b.name)));
    }

    // Group a homogeneous list (all sinks or all sources) by card. The group
    // holding defaultNodeId sorts first, then by highest session priority.
    function groupByDevice(nodes, defaultNodeId) {
        const buckets = ({});
        const order = [];
        for (const node of nodes) {
            const key = deviceId(node) || ("node:" + node.id);
            if (buckets[key] === undefined) {
                buckets[key] = [];
                order.push(key);
            }
            buckets[key].push(node);
        }

        const groups = [];
        for (const key of order) {
            const members = sortNodes(buckets[key]);
            groups.push({
                key: key,
                label: deviceLabel(members),
                icon: deviceIcon(members),
                isDefault: defaultNodeId !== undefined && defaultNodeId >= 0
                    && members.some(n => n.id === defaultNodeId),
                nodes: members
            });
        }

        groups.sort((a, b) =>
            (b.isDefault - a.isDefault)
            || (bestPriority(b.nodes) - bestPriority(a.nodes))
            || String(a.label).localeCompare(String(b.label)));
        return groups;
    }
}
