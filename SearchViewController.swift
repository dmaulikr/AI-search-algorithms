//
//  SWIFT Implementation of the Null Move Quiescence Search and
//  Alpha-Beta Algorithms
//
//  Created by Samuel Pineda.
//

import UIKit

class SearchViewController: UIViewController, UITextFieldDelegate {
    
    // Outlets for textFields and switch
    @IBOutlet weak var bField: UITextField!
    @IBOutlet weak var vField: UITextField!
    @IBOutlet weak var hField: UITextField!
    @IBOutlet weak var iField: UITextField!
    @IBOutlet weak var sField: UITextField!
    @IBOutlet weak var debugModeOutlet: UISwitch!
    
    
    // Constant for infinity
    let infinity = Int.max
    
    
    // Default top node values
    struct tnDefaults {
        static let b = 2
        static let h = 3
        static let v = 100
        static let i = 5
        static let s = 20
    }
    
    
    // Static evaluations counter
    var staticEvCounter = 0
    
    
    // Variables for printing purposes
    var debugOn = true
    var printStack = [(String, Int)]()
    var lowestIndLevel = 0;
    
    
    // Function executed when the user taps the "Start" button
    @IBAction func startButton(_ sender: UIButton) {
        var b = tnDefaults.b
        var h = tnDefaults.h
        var v = tnDefaults.v
        var i = tnDefaults.i
        var s = tnDefaults.s
        
        // Get values from text fields
        if let bInt = Int((bField?.text)!) { if bInt >= 0 { b = bInt } }
        if let hInt = Int((hField?.text)!) { if hInt >= 0 { h = hInt } }
        if let vInt = Int((vField?.text)!) { v = vInt }
        if let iInt = Int((iField?.text)!) { if iInt >= 0 { i = iInt } }
        if let sInt = Int((sField?.text)!) { if sInt >= 0 { s = sInt } }
        
        // Automatically turn off debug mode if
        // the tree is relatively big
        if b > 3 || h > 3 {
            debugOn = false
        }
        
        printConsoleTitle(str: "TOP NODE VALUES")
        print("b: \(b)")
        print("h: \(h)")
        print("v: \(v)")
        print("i: \(i)")
        print("s: \(s)")
        
        let rootNode = createTree(b: b, h: h, v: v, i: i, s: s)
        
        
        // Displays in cosole a JSON representation of the tree that can be parsed
        // with any online JSON parser (e.g. http://jsonparseronline.com)
        if debugOn {
            let jsonStr = getJSONRepresentationOfTree(node: rootNode)
            printConsoleTitle(str: "JSON REPRESENTATION OF THE TREE")
            print(jsonStr)
        }
        
        for searchDepth in 0 ... h {
            staticEvCounter = 0
            let abResult = alphaBeta(node: rootNode,
                                     height: searchDepth,
                                     alpha: -infinity,
                                     beta: infinity,
                                     useQuiescence: false)
            printDebugStack(title: "Simple Alpha-Beta (depth = \(searchDepth))",
                            result: abResult,
                            evCounter: staticEvCounter)
            
            staticEvCounter = 0
            let nmResult = alphaBeta(node: rootNode,
                                     height: searchDepth,
                                     alpha: -infinity,
                                     beta: infinity,
                                     useQuiescence: true)
            printDebugStack(title: "A-B with Null Move Quiescence (depth = \(searchDepth))",
                            result: nmResult,
                            evCounter:staticEvCounter)
        }
        
        printConsoleTitle(str: "DONE")
    }
    
    // Function for generating a fixed-width fixed-depth sample game tree.
    // Paramenters:
    // b: branching factor of the tree
    // h: height of the tree
    // v: node true value
    // i: inaccuracy of the node (for simulating purposes)
    // s: spread of child nodes
    func createTree(b: Int, h: Int, v: Int, i: Int, s: Int) -> Node {
        let newNode = Node(estimatedValue: v)
        
        if h > 0 {
            let randomI = Int(arc4random_uniform(UInt32(2*i + 1))) - i
            newNode.estimatedValue = newNode.estimatedValue + randomI
        }
        
        if h > 0 {
            let luckyChildIndex = Int(arc4random_uniform(UInt32(b)))
            for j in 0 ..< b {
                var childTrueValue = 0
                if j == luckyChildIndex {
                    childTrueValue = -v
                } else {
                    childTrueValue = -v + Int(arc4random_uniform(UInt32(s+1)))
                }
                newNode.addChild(n: createTree(b: b, h: h-1, v: childTrueValue, i: i, s: s))
            }
        }
        return newNode
    }
    
    
    // Implementation of negamax variant of alpha-beta
    func alphaBeta(node: Node, height: Int, alpha: Int, beta: Int, useQuiescence: Bool) -> Int {
        var alpha = alpha
        
        if height == 0 {
            var eval = 0
            
            if useQuiescence {
                eval = NMQuiesce(node: node,
                                 lower: -infinity,
                                 upper: infinity,
                                 depthForPrinting: 0)
            } else {
                eval = evaluation(node: node)
                if debugOn {
                    appendToPrintStack(line: "{estValue: \(node.estimatedValue), " +
                                             "h: \(height), " +
                                             "ab: (\(alpha), \(beta)), " +
                                             "eval: \(eval), " +
                                             "method: \"Static (regular)\"}",
                                       indLevel: height)
                }
            }
            return eval
            
        } else {
            var temp = 0
            
            for child in node.children {
                temp = -alphaBeta(node: child,
                                  height: height-1,
                                  alpha: -beta,
                                  beta: -alpha,
                                  useQuiescence: useQuiescence)
                
                if temp >= beta {
                    if debugOn {
                        appendToPrintStack(line: "{estValue: \(node.estimatedValue), " +
                                                 "h: \(height), " +
                                                 "ab: (\(temp), \(beta)), " +
                                                 "eval: \(temp), " +
                                                 "method: \"Search\"}",
                                           indLevel: height)
                    }
                    return temp
                }
                alpha = max(temp, alpha)
            }
            
            if debugOn {
                appendToPrintStack(line: "{estValue: \(node.estimatedValue), " +
                                         "h: \(height), " +
                                         "ab: (\(alpha), \(beta)), " +
                                         "eval: \(alpha), " +
                                         "method: \"Search\"}",
                                   indLevel: height);
            }
            return alpha
        }
    }

    
    // Implementation of Null Move Quiescence Search algorithm
    func NMQuiesce(node: Node, lower: Int, upper: Int, depthForPrinting: Int) -> Int {
        var temp = 0, best = 0
        
        // Generate null move and evaluate it
        let nullMoveNode = Node(estimatedValue: -node.estimatedValue)
        staticEvCounter = staticEvCounter + 1
        
        // Use the null move evaluation
        best = -nullMoveNode.estimatedValue
        
        for child in node.children {
            if best >= upper {
                if debugOn {
                    appendToPrintStack(line: "{estValue: \(node.estimatedValue), " +
                                             "depth: \(depthForPrinting), " +
                                             "lower: \(lower), " +
                                             "upper: \(upper), " +
                                             "best: \(best), " +
                                             "method: \"Static (NMQuiesce)\"}",
                                       indLevel: depthForPrinting)
                }
                return best
            }
            
            temp = -NMQuiesce(node: child,
                              lower: -upper,
                              upper: -best,
                              depthForPrinting: depthForPrinting - 1)
            best = max(best, temp)
        }
        
        if debugOn {
            appendToPrintStack(line: "{estValue: \(node.estimatedValue), " +
                                     "depth: \(depthForPrinting), " +
                                     "lower: \(lower), " +
                                     "upper: \(upper), " +
                                     "best: \(best), " +
                                     "method: \"Static (NMQuiesce)\"}",
                               indLevel: depthForPrinting)
        }
        return best
    }
    
    
    // Simple function for static evaluations
    func evaluation(node: Node) -> Int {
        staticEvCounter = staticEvCounter + 1
        return node.estimatedValue
    }
    
    
    // Returns the maximum value of 2 integers
    func max(_ x: Int, _ y: Int) -> Int {
        return (x < y) ? y : x
    }
    
    
    // Utility function for indenting in debug Mode
    func getIndentStr(height: Int) -> String {
        var str = ""
        for _ in 0 ..< height {
            str = str + "\t"
        }
        return str
    }
    
    
    // Utility function for managing debug stack
    func appendToPrintStack(line: String, indLevel: Int) {
        printStack.append((line, indLevel))
        if indLevel < lowestIndLevel {
            lowestIndLevel = indLevel
        }
    }
    
    
    // Utility function for printing the debug stack
    func printDebugStack(title: String, result: Int, evCounter: Int) {
        print("\n---------------------------------------------------------------------------")
        print(" \(title):")
        print("---------------------------------------------------------------------------\n")
        
        for (line, indLevel) in printStack {
            var indentStr = ""
            let indent = indLevel - lowestIndLevel
            for _ in (0 ..< indent) {
                indentStr = indentStr + "\t"
            }
            print(indentStr + line.replacingOccurrences(of: "\(infinity)", with: "∞"))
        }
        
        if !printStack.isEmpty { print("") }
        print("-> RESULT: value = \(result), static evaluations = \(evCounter)")
        printStack.removeAll()
        lowestIndLevel = 0
    }
    
    
    // Utility function for getting the JSON representation of a tree
    func getJSONRepresentationOfTree(node: Node) -> String {
        var str = "{\"ev\": \(node.estimatedValue), \"children\": ["
        for (index, child) in node.children.enumerated() {
            str = str + getJSONRepresentationOfTree(node: child)
            if index < node.children.count - 1 {
                str = str + ", "
            }
        }
        str = str + "]}"
        return str
    }
    
    
    func printConsoleTitle(str: String) {
        print("\n---------------------------------------------------------------------------")
        print(" \(str):")
        print("---------------------------------------------------------------------------\n")
    }
    
    @IBAction func debugSwitchChanged(_ sender: UISwitch) {
        debugOn = sender.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        bField.placeholder = "\(tnDefaults.b)"
        hField.placeholder = "\(tnDefaults.h)"
        vField.placeholder = "\(tnDefaults.v)"
        iField.placeholder = "\(tnDefaults.i)"
        sField.placeholder = "\(tnDefaults.s)"
        
        bField.delegate = self
        hField.delegate = self
        vField.delegate = self
        iField.delegate = self
        sField.delegate = self
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
