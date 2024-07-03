// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

address constant SENTINEL = address(0x1);
address constant ZERO_ADDRESS = address(0x0);

library SentinelListLib {
    struct SentinelList {
        mapping(address => address) entries;
    }

    error LinkedList_AlreadyInitialized();
    error LinkedList_InvalidPage();
    error LinkedList_InvalidEntry(address entry);
    error LinkedList_EntryAlreadyInList(address entry);

    function init(SentinelList storage self) internal {
        if (alreadyInitialized(self)) revert LinkedList_AlreadyInitialized();
        self.entries[SENTINEL] = SENTINEL;
    }

    function alreadyInitialized(SentinelList storage self) internal view returns (bool) {
        return self.entries[SENTINEL] != ZERO_ADDRESS;
    }

    function getNext(SentinelList storage self, address entry) internal view returns (address) {
        if (entry == ZERO_ADDRESS) {
            revert LinkedList_InvalidEntry(entry);
        }
        return self.entries[entry];
    }

    function push(SentinelList storage self, address newEntry) internal {
        if (newEntry == ZERO_ADDRESS || newEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(newEntry);
        }
        if (self.entries[newEntry] != ZERO_ADDRESS) revert LinkedList_EntryAlreadyInList(newEntry);
        self.entries[newEntry] = self.entries[SENTINEL];
        self.entries[SENTINEL] = newEntry;
    }

    function pop(SentinelList storage self, address prevEntry, address popEntry) internal {
        if (popEntry == ZERO_ADDRESS || popEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(prevEntry);
        }
        if (self.entries[prevEntry] != popEntry) revert LinkedList_InvalidEntry(popEntry);
        self.entries[prevEntry] = self.entries[popEntry];
        self.entries[popEntry] = ZERO_ADDRESS;
    }

    function popAll(SentinelList storage self) internal {
        address next = self.entries[SENTINEL];
        while (next != ZERO_ADDRESS) {
            address current = next;
            next = self.entries[next];
            self.entries[current] = ZERO_ADDRESS;
        }
        self.entries[SENTINEL] = ZERO_ADDRESS;
    }

    function contains(SentinelList storage self, address entry) internal view returns (bool) {
        return SENTINEL != entry && self.entries[entry] != ZERO_ADDRESS;
    }

    function getEntriesPaginated(
        SentinelList storage self,
        address start,
        uint256 pageSize
    )
        internal
        view
        returns (address[] memory array, address next)
    {
        if (start != SENTINEL && !contains(self, start)) revert LinkedList_InvalidEntry(start);
        if (pageSize == 0) revert LinkedList_InvalidPage();
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 entryCount = 0;
        next = self.entries[start];
        while (next != ZERO_ADDRESS && next != SENTINEL && entryCount < pageSize) {
            array[entryCount] = next;
            next = self.entries[next];
            entryCount++;
        }

        /**
         * Because of the argument validation, we can assume that the loop will always iterate over
         * the valid entry list values
         *       and the `next` variable will either be an enabled entry or a sentinel address
         * (signalling the end).
         *
         *       If we haven't reached the end inside the loop, we need to set the next pointer to
         * the last element of the entry array
         *       because the `next` variable (which is a entry by itself) acting as a pointer to the
         * start of the next page is neither
         *       incSENTINELrent page, nor will it be included in the next one if you pass it as a
         * start.
         */
        if (next != SENTINEL && entryCount > 0) {
            next = array[entryCount - 1];
        }
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        /// @solidity memory-safe-assembly
        assembly {
            mstore(array, entryCount)
        }
    }

    function getAllEntries(SentinelList storage self) internal view returns (address[] memory) {
        uint totalEntries = 0;
        address current = self.entries[SENTINEL];
        // Count total entries
        while(current != SENTINEL) {
            totalEntries++;
            current = self.entries[current];
        }

        // Allocate array for all entries
        address[] memory allEntries = new address[](totalEntries);
        current = self.entries[SENTINEL]; // Reset current to start from sentinel again

        // Collect all entries
        for(uint i = 0; i < totalEntries; i++) {
            allEntries[i] = current;
            current = self.entries[current];
        }

        return allEntries;
    }

    function getAllEntriesViaPagination(SentinelList storage self) internal view returns (address[] memory) {
        uint256 pageSize = 50; // Example page size, adjust based on expected list sizes and gas considerations
        address start = SENTINEL;
        address[] memory tempArray;
        address next;
        uint256 totalEntries = 0;

        // First, determine the total number of entries to allocate memory efficiently
        (tempArray, next) = getEntriesPaginated(self, start, pageSize);
        while (next != SENTINEL) {
            totalEntries += tempArray.length;
            (tempArray, next) = getEntriesPaginated(self, next, pageSize);
        }
        // Add the count of the last page
        totalEntries += tempArray.length;

        // Allocate memory for the final array
        address[] memory allEntries = new address[](totalEntries);

        // Reset for actual collection
        start = SENTINEL;
        uint256 currentIndex = 0;

        // Collect all entries
        do {
            (tempArray, next) = getEntriesPaginated(self, start, pageSize);
            for (uint256 i = 0; i < tempArray.length; i++) {
                allEntries[currentIndex++] = tempArray[i];
            }
            start = next;
        } while (next != SENTINEL);

        return allEntries;
    }
}
