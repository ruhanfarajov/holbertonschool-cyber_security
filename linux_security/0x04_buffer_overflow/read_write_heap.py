#!/usr/bin/python3
import sys
i


def usage():
    print("Usage: read_write_heap.py pid search_string replace_string")
    sys.exit(1)


def find_heap_range(pid):
    maps_path = f"/proc/{pid}/maps"

    try:
        with open(maps_path, "r") as f:
            for line in f:
                if "[heap]" in line:
                    addr_range = line.split()[0]
                    start, end = addr_range.split("-")
                    return int(start, 16), int(end, 16)
    except Exception:
        print("Error: cannot read /proc/pid/maps (invalid pid or permission)")
        sys.exit(1)

    print("Error: heap not found")
    sys.exit(1)


def main():
    if len(sys.argv) != 4:
        usage()

    pid = sys.argv[1]
    search = sys.argv[2].encode()
    replace = sys.argv[3].encode()

    heap_start, heap_end = find_heap_range(pid)
    heap_size = heap_end - heap_start

    mem_path = f"/proc/{pid}/mem"

    try:
        mem = open(mem_path, "rb+")
    except PermissionError:
        print("Error: permission denied (try sudo)")
        sys.exit(1)
    except Exception:
        print("Error: cannot open /proc/pid/mem")
        sys.exit(1)

    print(f"[*] PID: {pid}")
    print(f"[*] Heap: {hex(heap_start)} - {hex(heap_end)}")
    print(f"[*] Searching: {search.decode()}")
    print(f"[*] Replacing with: {replace.decode()}")

    # safety check
    if len(replace) > len(search):
        print("Error: replace_string cannot be longer than search_string")
        sys.exit(1)

    mem.seek(heap_start)
    heap_data = mem.read(heap_size)

    occurrences = 0
    offset = 0

    while True:
        idx = heap_data.find(search, offset)
        if idx == -1:
            break

        real_addr = heap_start + idx
        print(f"[+] Found at {hex(real_addr)}")

        mem.seek(real_addr)

        # ✅ correct padding: spaces forced to end
        data = (replace + b' ' * len(search))[:len(search)]
        mem.write(data)

        occurrences += 1
        offset = idx + 1

    if occurrences == 0:
        print("[-] No occurrences found")
    else:
        print(f"[+] Total replacements: {occurrences}")

    mem.close()


if __name__ == "__main__":
    main()
