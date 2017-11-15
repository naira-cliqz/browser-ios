//
//  StateGlobals.swift
//  Client
//
//  Created by Tim Palade on 11/14/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

enum MainState {
    case tabsVisible
    case reminderVisible
    case actionSheetVisible
    case other
}

enum ContentState {
    case browse
    case search
    case domains
    case details
    case dash
}

enum URLBarState {
    case collapsedEmptyTransparent
    case collapsedTextTransparent
    case collapsedTextBlue //displays query
    case collapsedDomainBlue //displays domain
    case expandedEmptyWhite
    case expandedTextWhite
}

enum ToolBarState {
    case invisible
    case visible
}

enum ToolBarBackState {
    case enabled
    case disabled
}

enum ToolBarForwardState {
    case enabled
    case disabled
}

enum ToolBarShareState {
    case enabled
    case disabled
}

//Have a place where you create the StateData from the action. Or even better, modify the action such that it will send state data.
struct StateData: Equatable {
    let query: String?
    let url: String?
    weak var tab: Tab?
    let detailsHost: String?
    //maybe indexpath as well or tab?
    
    static func merge(lhs: StateData, rhs: StateData) -> StateData {
        //lhs takes precedence
        
        let query = lhs.query != nil ? lhs.query : rhs.query
        let url   = lhs.url != nil ? lhs.url : rhs.url
        let tab   = lhs.tab != nil ? lhs.tab : rhs.tab
        let detailsHost = lhs.detailsHost != nil ? lhs.detailsHost : rhs.detailsHost
        
        return StateData(query: query, url: url, tab: tab, detailsHost: detailsHost)
    }
    
    static func == (lhs: StateData, rhs: StateData) -> Bool {
        //I don't care about the indexPath and image. They can be different.
        //If I care about them, I can have identical states in the BackForwardNavigation that differ only because of this.
        //Case to see this: browse -> domains -> details -> domains...there will be 2 domains registered with different indexPaths
        return lhs.query == rhs.query && lhs.url == rhs.url && lhs.tab == rhs.tab
    }
    
    static func empty() -> StateData {
        return StateData(query: nil, url: nil, tab: nil, detailsHost: nil)
    }
    
    static func fromAction(action: Action) -> StateData {
        
        guard let data = action.data else {
            return StateData(query: nil, url: nil, tab: nil, detailsHost: nil)
        }
        
        let text = data["text"] as? String
        let tab  = data["tab"] as? Tab
        let detailsHost = data["detailsHost"] as? String
        var url  = data["url"] as? String
        
        if let u = url, let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile {
            var validURL = URIFixup.getURL(u)
            if validURL == nil {
                validURL = profile.searchEngines.defaultEngine.searchURLForQuery(u)
            }
            url = validURL?.absoluteString
        }
        
        return StateData(query: text, url: url, tab: tab, detailsHost: detailsHost)
    }
    
}


//Careful about this. There are 2 equality rules. One when all the states are the same but the state data is different (==). The other when everything is identical including the stateData (equalWithTheSameData).
struct State: Equatable {
    //let mainState: MainState
    let contentState: ContentState
    let urlBarState: URLBarState
    let toolBarState: ToolBarState
    let toolBackState: ToolBarBackState
    let toolForwardState: ToolBarForwardState
    let toolShareState: ToolBarShareState
    
    let stateData: StateData
    
    static func == (lhs: State, rhs: State) -> Bool {
        return lhs.contentState == rhs.contentState && lhs.urlBarState == rhs.urlBarState && lhs.toolBarState == rhs.toolBarState //&& lhs.toolBackState == rhs.toolBackState && lhs.toolForwardState == rhs.toolForwardState && lhs.toolShareState == rhs.toolShareState
    }
    
    static func equalWithTheSameData (lhs: State, rhs: State) -> Bool {
        return lhs == rhs && lhs.stateData == rhs.stateData
    }
    
    static func initial() -> State {
        return State(contentState: .domains, urlBarState: .collapsedEmptyTransparent, toolBarState: .visible, toolBackState: .disabled, toolForwardState: .disabled, toolShareState: .disabled, stateData: StateData.empty())
    }
}

extension State {
    func sameStateWithNewData(newStateData: StateData) -> State {
        return sameStateWith(info: ["stateData": newStateData])
    }
    
    func sameStateWithNewBackForwardState(newBackState: ToolBarBackState, newForwardState: ToolBarForwardState) -> State {
        return sameStateWith(info: ["toolBackState": newBackState, "toolForwardState": newForwardState])
    }
    
    func sameStateWith(info: [String: Any]) -> State {
        
        let new_contentState: ContentState? = info["contentState"] as? ContentState
        let new_urlBarState: URLBarState? = info["urlBarState"] as? URLBarState
        let new_toolBarState: ToolBarState? = info["toolBarState"] as? ToolBarState
        let new_toolBackState: ToolBarBackState? = info["toolBackState"] as? ToolBarBackState
        let new_toolForwardState: ToolBarForwardState? = info["toolForwardState"] as? ToolBarForwardState
        let new_toolShareState: ToolBarShareState? = info["toolShareState"] as? ToolBarShareState
        let new_stateData: StateData? = info["stateData"] as? StateData
        
        let contentState: ContentState = new_contentState != nil ? new_contentState! : self.contentState
        let urlBarState: URLBarState = new_urlBarState != nil ? new_urlBarState! : self.urlBarState
        let toolBarState: ToolBarState = new_toolBarState != nil ? new_toolBarState! : self.toolBarState
        let toolBackState: ToolBarBackState = new_toolBackState != nil ? new_toolBackState! : self.toolBackState
        let toolForwardState: ToolBarForwardState = new_toolForwardState != nil ? new_toolForwardState! : self.toolForwardState
        let toolShareState: ToolBarShareState = new_toolShareState != nil ? new_toolShareState! : self.toolShareState
        let stateData: StateData = new_stateData != nil ? new_stateData! : self.stateData
        
        return State(contentState: contentState, urlBarState: urlBarState, toolBarState: toolBarState, toolBackState: toolBackState, toolForwardState: toolForwardState, toolShareState: toolShareState, stateData: stateData)
        
    }
}