// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   10
//   100
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P16 code block of
// docs/design/interoperability/threads_and_atomics.md, section "In the 0.1
// toolchain", byte for byte (fork/designdocs/check_samples.py, rulebook R27).
// Expected output derived by hand in fork/designdocs/plan.md section 4
// (R16(d)). Runs on this fork's toolchain and on the upstream nightly. A PASS
// shows that the documented sample runs as documented; the design-docs bullet
// itself is arbitrated by document review.

import Core library "io";
import Cpp library "<atomic>";
import Cpp library "<mutex>";
import Cpp library "<thread>";

import Cpp inline '''c++
inline thread_local int per_thread = 0;
''';

// Atomicity is a property of the object's type, an imported C++ type.
var hits: Cpp.std.atomic(i32);
// An ordinary Carbon variable, protected by a C++ mutex.
var total: i32 = 0;
var total_mutex: Cpp.std.mutex;

fn Work() {
  hits.fetch_add(1);
  Cpp.per_thread += 5;
  // The guard's C++ destructor unlocks the mutex at Carbon scope exit.
  var unused lock: Cpp.std.lock_guard(Cpp.std.mutex) =
      Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref total_mutex);
  total += Cpp.per_thread;
}

fn Run() -> i32 {
  Cpp.per_thread = 100;
  // A `std::thread` runs a Carbon function directly.
  var a: Cpp.std.thread = Cpp.std.thread.thread(Work);
  var b: Cpp.std.thread = Cpp.std.thread.thread(Work);
  a.join();
  b.join();
  // Each thread saw its own `per_thread`, starting at zero.
  Core.Print(hits.load());
  Core.Print(total);
  Core.Print(Cpp.per_thread);
  return 0;
}
