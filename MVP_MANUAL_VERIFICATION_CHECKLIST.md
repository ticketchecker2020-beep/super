# MVP Manual Verification Checklist (TASK-008)

Use on iPhone simulator/device and watch Xcode debug console logs.

- [ ] Open a list, tap **Enter Shopping Mode**, verify log: `entering_shopping_mode`.
- [ ] Confirm speech starts for queued item(s), verify log: `speech_start`.
- [ ] Tap **Repeat**, verify log: `repeat_action`.
- [ ] Tap **Next / Mark Done**, verify logs: `advance` and queue refresh log.
- [ ] Send remote command `done` in debug field, verify logs: `remote_input_received` and `mark_done`.
- [ ] Tap **Read Next 3**, verify log: `read_next_3`.
- [ ] Tap **Log Queue** and confirm queue snapshot appears in console.
- [ ] Confirm on-screen **Debug** queue snapshot matches visible remaining items.
