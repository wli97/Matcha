current <- vector("list", 1)
# update process can be improved with index checker, no need to reload past data
update <- function(){
  i<-0L
  current <<- vector("list", 1)
  while(TRUE){
    valid <- getValid(USER$Address,i)
    if(length(valid) <= 1) break
    request <- getRequest(valid[[1]], valid[[2]])
    # if no timestamp, it is empty
    if(request[1] < 1) break
    # if(request[4] != 6){
    request <- formatRequest(request,i)
    i <- i+1L
    current[[i]] <<- request 
  }
}
update()

output$page <- renderUI({
  div(
    material_side_nav(
      fixed = TRUE,
      image_source = "img/tdb.PNG",
      tags$div(h5("Bank Portal"),align="center"),
      material_side_nav_tabs(
        side_nav_tabs = c(
          "Current Claims" = "current"
          ,"Search Client" = "history"
          ,"Fund Money" = "qa"
        ),
        icons = c("monetization_on"
                  ,"insert_chart"
                  ,"payment"
        )
      )
    ),
    
    material_side_nav_tab_content(
      side_nav_tab_id = "current",
      searchRequest(current,"Current Client Requests",FALSE),
      uiOutput("reqDetail")
    ),
    
    material_side_nav_tab_content(
      side_nav_tab_id = "history",
      material_card(
        material_row(
          material_column(
            h5("Search Client")
          )
        ),
        material_row(
          material_column(
            width = 5,
            material_text_box(
              input_id = "CAddress",
              label = "Address of the client",
              color = "green"
            )
          ),
          material_column(
            width = 2,
            actionButton("getC", "Search!", icon("search"), 
                         style="color: #fff; background-color: #00B624;")
          ),
          material_column(
            width = 3,
            material_dropdown(
              input_id = "Ctype",
              label = "Type",
              color = "green",
              choices = c(
                "Client" = 4L,
                "Police" = 2L,
                "Repair" = 3L
              )
            )
          ),
          material_column(
            width = 2,
            actionButton("addC", "Add", icon("user-plus"), 
                         style="color: #fff; background-color: #FFCC00;")
          )
        )
      ),
      uiOutput("clientReq")
    ),
    
    material_side_nav_tab_content(
      side_nav_tab_id = "qa",
      material_parallax(
        './img/td_bank.jpg'
      ),
      material_card(
        h5("Fund Money to Matcha"),
        actionButton("fund", "Fund 1 Ether", icon("dollar-sign"), 
                     style="color: #fff; background-color: #FFCC00;"),
        actionButton("check", "Balance", icon("credit-card"), 
                     style="color: #fff; background-color: #00B624;"),
        br(),
        uiOutput("msg")
      )
    )
  )
})

##############################
## APP SERVER for BANK
############################## 

observeEvent(input$det, {
  if(input$det > 0 && input$req != "NULL"){
    index <- as.integer(input$req)
    output$reqDetail <- renderUI({
      request(current[[index]],material_row(
        material_column(width=5, material_text_box(
          input_id = "validA", 
          label = "Optional: append any justification.",
          color = "green"
        )),
        material_column(width=3, material_number_box(
          input_id = "validD",
          label = "Payment Amount",
          initial_value = 0,
          min_value = 0,
          max_value = 1000000,
          color = "green"
        )),
        actionButton("validB", "Valid", icon("check"), 
                     style="color: #fff; background-color: #00B624; border-color: #2e6da4"),
        actionButton("validC", "Invalid", icon("times"), 
                     style="color: #fff; background-color: red; border-color: #2e6da4"),
        uiOutput("submitStat")
      ))
    })
    output$submitStat <- renderUI({div()})
  }
  else{
    output$reqDetail <- renderUI({div()})
    output$valid <- renderUI({div()})
  }
})

observeEvent(input$req,{
  output$reqDetail <- renderUI({div()})
  output$valid <- renderUI({div()})
  output$submitStat <- renderUI({div()})
})

observeEvent(input$validB, {
  if(input$validB < 1){} else{
    resp <- payClaim(current[[as.integer(input$req)]][[9]], TRUE, paste0(" BK ",": ",Sys.time(),"-",input$validA), as.integer(input$validD))
    if(resp == 0){
      output$submitStat <- renderUI({
        div(h6("Validation failed, please try again later."), style="color:red")
      })
    }
    else{
      update_material_text_box(session, "desc", value="")
      output$reqDetail <- renderUI({div()})
      update()
      update_material_dropdown(session,"req",value="NULL",choices=requests(current))
    }      
  }
})

observeEvent(input$validC, {
  if(input$validC < 1){} else{
    resp <- payClaim(current[[as.integer(input$req)]][[9]], FALSE, paste0(" BK ",": ",Sys.time(),"-",input$validA),input$validD)
    if(resp == 0){
      output$submitStat <- renderUI({
        div(h6("Validation failed, please try again later."), style="color:red")
      })
    }
    else{
      update_material_text_box(session, "desc", value="")
      output$reqDetail <- renderUI({div()})
      update()
      update_material_dropdown(session,"req",value="NULL",choices=requests(current))
    }}      
})

observeEvent(input$fund, {
  if(input$fund >0 && inject() > 0){
    output$msg <- renderUI({
      div(h6("Injection Successful."), style="color:green")
    })
  } else{
    output$msg <- renderUI({
      div(h6("Injection Failed."), style="color:red")
    })
  }
})

observeEvent(input$check, {
  f <- checkFund()
  #test()
  output$msg <- renderUI({
    div(h5("Amount: ", f, " Ether. "), style="color:green")
  })
})

observeEvent(input$getC, {
  if(input$getC != ""){
    client <- getClient(input$CAddress)
    userInfo <- getUser(input$CAddress)
    if(userInfo == 1) userInfo <- "Insurance Company"
    else if(userInfo == 2) userInfo <- "Police/Watcher"
    else if(userInfo == 3) userInfo <- "Garage/Repair"
    else if(userInfo == 4) userInfo <- "Client"
    else userInfo <- "Access Denied, or Address not recognized"
    if( is.null(client) ){
      output$clientReq <- renderUI({
        material_card(
          material_row(h5(paste0("Address type: ", userInfo))),
          material_row(h5("No submitted requests"))
        )
      })
    } else{
      output$clientReq <- renderUI({
        div(
          material_row(h5(paste0("Address type: ", userInfo))),
          lapply(1:length(client), function(i) {
            request(client[[i]])
          })
        )
      })
    }
  }
})

observeEvent(input$addC,{
  if(input$CAddress != ""){
    status <- addUser(input$CAddress, as.integer(input$Ctype))
    print(input$CAddress)
    print(input$Ctype)
    if(status != 0){
      output$clientReq <- renderUI({
        material_card(h5("Client successfully added."))
      })
    } else{
      output$clientReq <- renderUI({
        material_card(h5("Client not added, verify address."))
      })  
    }
  }
})

getClient <- function(address){
  client <- vector("list", 1)
  i <- 0L
  while(TRUE){
    request <- getRequest(address, i)
    print(request)
    if(request[[1]] < 1) break
    request <- formatRequest(request, i)
    i <- i+1L
    client[[i]] <- request
  }
  if(i == 0) return()
  return(client)
}