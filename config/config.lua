config = {}

config.installDB = "USE `zirix`; CREATE TABLE IF NOT EXISTS `groups_garages` (`id` int(11) NOT NULL AUTO_INCREMENT,`vehicleName` varchar(50) NOT NULL,`groupName` varchar(50) NOT NULL,`count` int(10) NOT NULL,`arresting` int(11) NOT NULL,`time` timestamp NOT NULL DEFAULT current_timestamp(),PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
config.isInstalled = false

config.groups = {}

config.groupsGarages = {
	["ballas"] = { ['x'] = 1266.67, ['y'] = -220.5, ['z'] = 100.23 },
	["grove"] = { ['x'] = 1264.67, ['y'] = -220.62, ['z'] = 100.23 },
}

config.groupsVehicles = {
	["ballas"] = {
		["a45"] = { ["nome"] = "a45", ["price"] = 500, ["qtd"] = 0, ["limit"] = 5 }
	},
	["grove"] = {
		["rmodmk7"] = { ["nome"] = "rmodmk7", ["price"] = 200000, ["qtd"] = 0, ["limit"] = 5 },
		["p1"] = { ["nome"] = "p1", ["price"] = 200000, ["qtd"] = 0, ["limit"] = 5 }
	},
}