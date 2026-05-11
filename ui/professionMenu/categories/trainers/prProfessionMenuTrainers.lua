local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu

ProfessionMenu:RegisterCategoryInitializer(function(menu)
	menu:CreateTrainerMenuView()
	menu:CreateTrainerDetailView()
	menu:CreateTrainerTeachesView()
end)

ProfessionMenu:RegisterSectionHandler("trainers", function(menu)
	menu:GoToTrainerMenu()
end)
