import Foundation

// String of characters to be used for generating patterns
let str = "🟥🟩🟨🌑"

// Function to get character at specific offset in a string
func charAt(_ str:String, _ offset:Int) -> String {
    let index = str.index(str.startIndex, offsetBy: offset)
    let char = str[index]
    return String(char)
}

// Function to generate a line of random characters of given length
func generateLine(_ n:Int) {
    var nstr = ""
    for _ in 0..<n {
        let randomInt = Int.random(in: 0..<str.count)
        nstr += charAt(str, randomInt)
    }
    print(nstr)
}

// Function to generate a block of lines
func generateBlock(_ n: Int) {
    for _ in 0..<n {
        generateLine(n)
    }
}

// Generate three blocks of 5 lines each
generateBlock(5)
print("")
generateBlock(5)
print("")
generateBlock(5)
