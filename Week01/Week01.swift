import Foundation

let str = "👋
🤚
🖐
✋
🖖
👌
🤌
🤏
✌️
🤞
🫰
🤟
🤘
🤙
🫵
🫱"

func charAt(_ str:String, _ offset:Int) -> String {
    let index = str.index(str.startIndex, offsetBy: offset)
    let char = str[index]
    return String(char)
}


func generateLine(_ n:Int) {
    var nstr = ""
    for _ in 0..<n {
        let randomInt = Int.random(in: 0..<str.count)
        nstr += charAt(str, randomInt)
    }
    print(nstr)
}


func generateBlock(_ n: Int) {
    for _ in 0..<n {
        generateLine(n)
    }
}


generateBlock(5)
print("")
generateBlock(5)
print("")
generateBlock(5)
