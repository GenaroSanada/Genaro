var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var GNG =artifacts.require("GNG");
var GNR =artifacts.require("GNR");
var GNGExchanger = artifacts.require("GNGExchanger");
var GenaroTokenSale = artifacts.require("GenaroTokenSale");

module.exports=function(deployer,network){

	// deployer.deploy(MiniMeTokenFactory)
	// .then(()=>{
	// 	return MiniMeTokenFactory.deployed()
	// })
	// .then(f=>{
	// 	factory = f
	// 	return GNG.new(factory.address)
	// })
	// .then(g=>{
	// 	gng = g
	// 	// console.log('details: ',gng)
	// 	console.log('GNG address: ',gng.address)
	// 	return gng.controller()
	// })
	// .then(c=>{
	// 	controller=c
	// 	console.log('controller detail',controller)
	// 	return XGR.new(factory.address)
	// })
	// .then(x=>{
	// 	xgr = x
	// 	console.log("XGR address: ",xgr.address)
	// 	return GNGExchanger.new(gng.address,xgr.address)
	// })
	// .then(ex=>{
	// 	exchanger = ex
	// 	console.log("Exchanger address: ", exchanger)
	// 	return exchanger.collect()
	// })
	// .then(res=>{
	// 	console.log(res)
	// });

	// deployer.deploy(MiniMeTokenFactory)
	// .then(()=>{
	// 	return MiniMeTokenFactory.deployed()
	// })
	// .then(f=>{
	// 	factory = f
	// 	return XGR.new(factory.address)
	// })
	// .then(x=>{
	// 	xgr = x
	// 	console.log("XGR address: ",xgr.address)
	// 	return GNG.new(factory.address)
	// })
	// .then(g=>{
	// 	gng = g
	// 	console.log("GNG address: ",gng.address)
	// 	return GNGExchanger.new(gng.address,xgr.address)
	// 	// return GNGExchanger.new("0x08A5F22fb48600BF0f96Dc7A6B1d5E62bcf9F673",xgr.address)
	// })
	// .then(ex=>{
	// 	exchanger = ex
	// 	console.log("Exchanger address: ", exchanger.address)
	// 	return exchanger.collect()
	// })
	// .then(res=>{
	// 	console.log(res)
	// });

	// deployer.deploy(MiniMeTokenFactory)
	// .then(()=>{
	// 	return GNGExchanger.new("0x6B6aCc0F69989381B912715A28D6227D44f15E94","0x1711Cb6436E933C11e245314Ea724B99C8bDa748")
	// 	// return GNGExchanger.new("0x08A5F22fb48600BF0f96Dc7A6B1d5E62bcf9F673",xgr.address)
	// })
	// .then(ex=>{
	// 	exchanger = ex
	// 	console.log("Exchanger address: ", exchanger.address)
	// });

	deployer.deploy(MiniMeTokenFactory)
	.then(()=>{
		return MiniMeTokenFactory.deployed()
	})
	.then(f=>{
		factory = f 
		return GNR.new(factory.address);
	})
	.then(g=>{
		gnr = g
		// console.log('details: ',gng)
		console.log('GNR address: ',gnr.address)
	});
	// deployer.deploy(MiniMeTokenFactory)
	// .then(()=>{
	// 	return GNGExchanger.new("0x6B6aCc0F69989381B912715A28D6227D44f15E94","0x1711Cb6436E933C11e245314Ea724B99C8bDa748")
	// 	// return GNGExchanger.new("0x08A5F22fb48600BF0f96Dc7A6B1d5E62bcf9F673",xgr.address)
	// })
	// .then(ex=>{
	// 	exchanger = ex
	// 	console.log("Exchanger address: ", exchanger.address)
	// });	
} 

