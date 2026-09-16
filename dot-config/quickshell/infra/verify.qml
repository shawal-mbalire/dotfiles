pragma Singleton

import QtQuick
import Quickshell

// Infrastructure: port assertion logic. Verifies adapters against their
// port contracts at the composition root so a drifted adapter fails loud
// instead of misbehaving at runtime.
Singleton {
    function hasMethods(adapter, names) {
        if (!adapter) return false;
        for (const name of names)
            if (typeof adapter[name] !== "function") return false;
        return true;
    }

    function assertPort(adapter, names, portName) {
        if (!adapter)
            throw new Error("Adapter for " + portName + " is missing");
        for (const name of names) {
            if (typeof adapter[name] !== "function")
                throw new Error("Adapter does not implement " + portName + ":" + name);
        }
        return true;
    }

    function assertPorts(specs) {
        for (const spec of specs)
            assertPort(spec.adapter, spec.methods, spec.name);
        return true;
    }
}
