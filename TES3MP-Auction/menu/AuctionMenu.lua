Menus["Select"] = {
     text = "Welcome to the auction",
buttons = {						
            { caption = "Buy",
              destinations = {menuHelper.destinations.setDefault(nil,
              { 
				menuHelper.effects.runGlobalFunction(nil, "OnPlayerSendMessage",
					{menuHelper.variables.currentPid(), "/purchase"})
                })
              }
           },	
        { caption = "Sell",
           destinations = {menuHelper.destinations.setDefault(nil,
             { 
				menuHelper.effects.runGlobalFunction(nil, "OnPlayerSendMessage",
					{menuHelper.variables.currentPid(), "/selling"})
               })
             }
        }
   }
}