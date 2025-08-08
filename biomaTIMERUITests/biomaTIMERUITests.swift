import XCTest

final class biomaTIMERUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testMainTimerFlow() throws {
        let timerTab = app.tabBars.buttons["Timer"]
        XCTAssertTrue(timerTab.exists)
        timerTab.tap()
        
        let startButton = app.buttons.matching(identifier: "Start").firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        
        let stopButton = app.buttons.matching(identifier: "Stop").firstMatch
        XCTAssertTrue(stopButton.waitForExistence(timeout: 5))
        stopButton.tap()
    }
    
    func testProjectCreation() throws {
        let timerTab = app.tabBars.buttons["Timer"]
        timerTab.tap()
        
        let addProjectButton = app.buttons["plus.circle.fill"]
        if addProjectButton.exists {
            addProjectButton.tap()
            
            let nameField = app.textFields["Enter project name"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 5))
            nameField.tap()
            nameField.typeText("Test Project")
            
            let saveButton = app.buttons["Save Project"]
            XCTAssertTrue(saveButton.exists)
            saveButton.tap()
            
            XCTAssertTrue(app.staticTexts["Test Project"].waitForExistence(timeout: 5))
        }
    }
    
    func testHistoryView() throws {
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.exists)
        historyTab.tap()
        
        XCTAssertTrue(app.staticTexts["Work Time"].waitForExistence(timeout: 5))
        
        let weekButton = app.buttons["Week"]
        XCTAssertTrue(weekButton.exists)
        weekButton.tap()
        
        let monthButton = app.buttons["Month"]
        XCTAssertTrue(monthButton.exists)
        monthButton.tap()
    }
    
    func testSettingsView() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists)
        settingsTab.tap()
        
        XCTAssertTrue(app.staticTexts["Export to CSV"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Reset All Data"].exists)
    }
    
    func testExportFlow() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        
        let exportButton = app.staticTexts["Export to CSV"]
        exportButton.tap()
        
        let generateButton = app.buttons["Generate CSV"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()
    }
}