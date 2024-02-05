import Foundation

let path = URL(string: "https://raw.githubusercontent.com/yian6622/molab-2024-01-Yian/main/Week02/Text.txt")
let cowsStr = try String(contentsOf: path!, encoding: .utf8)
print("cowsStr.count", cowsStr.count)

let cowsSplit = cowsStr.split(separator: "\n", omittingEmptySubsequences: false)
print("cowsSplit.count \(cowsSplit.count)")
for index in 0...20 {
  let it = cowsSplit[index]
  print("\(it) \(it.count) \(index)")
}

for (index, value) in cowsSplit.enumerated() {
  if value.count == 0 && index < 50 {
    print("index \(index)")
  }
}

