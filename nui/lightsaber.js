var globalFac = '';

$(document).ready(function(){
	let actionContainer = $("#estacionamento");

	window.addEventListener('message', function(event){
		let item = event.data;
		
		switch(item.action){
			case 'showMenu':
				updateGarages(item.facName);
				globalFac = item.facName;
				actionContainer.fadeIn(700);
			break;

			case 'hideMenu':
				actionContainer.fadeOut(700);
			break;

			case 'updateGarages':
				updateGarages();
			break;
		}
	});

	document.onkeyup = function(data) {
		if (data.which == 27) {
			sendData("ButtonClick", "exit")
		}
	};
});

const formatarNumero = (n) => {
	var n = n.toString();
	var r = '';
	var x = 0;

	for (var i = n.length; i > 0; i--) {
		r += n.substr(i - 1, 1) + (x == 2 && i != 1 ? '.' : '');
		x = x == 2 ? 0 : x + 1;
	}
	return r.split('').reverse().join('');
}

const sendData = (name, data) => {
	$.post("http://vrp_factionsgarages/" + name, JSON.stringify(data), function(datab){});
}

const updateGarages = (facName) => {
	$("#nome p").text("Garagem: " + facName);
    $.post('http://vrp_factionsgarages/getFacVehicles', JSON.stringify({facName}), (data) => {
        $('#carros').html(`
            ${data.vehicles.map((item) => (`
				<div class="carro" data-carro-name="${item.foto}" data-carro-price="${item.preco}" data-carro-facName="${facName}">
					<div class="imagem">
						<img src="http://191.252.157.90/FIVEM/vrp_vehicles/${item.foto}.png"/>
					</div>
					<div class="nome">
						<p>Mercedes ${item.nome}</p>
					</div>
					<div class="box-list">
						<div class="box quantidade">
							<div class="titulo">
								<p>Quantidade</p>
							</div>
							<div class="valor">
								<p>${item.qtd}/${item.limit}</p>
							</div>
						</div>
						<div class="box preco">
							<div class="titulo">
								<p>R$ PREÇO</p>
							</div>
							<div class="valor">
								<p>${item.preco.toLocaleString("pt-BR", { style: "currency" , currency:"BRL"})}</p>
							</div>
							<div class="btn comprar" data-carro-name="${item.foto}" data-carro-price="${item.preco}" data-carro-facName="${facName}">Comprar</div>
						</div>
					</div>
				</div>
			`)).join('')}
		`);
	});
	
	var valor = 16.00;
	
}

$(document).on('click', '.carro', function(){
	let $el = $(this);
	let isActive = $el.hasClass('active');
	$('.carro').removeClass('active');
	if(!isActive) $el.addClass('active');
});

$(document).on('click', '.retirar', function(){
	let $el = $('.carro.active');
	if($el) {
		$.post('http://vrp_factionsgarages/spawnVehicle',JSON.stringify({
			nome: $el.attr('data-carro-name')
		}));
	}
});

$(document).on('click', '.guardar', function(){
	$.post('http://vrp_factionsgarages/storeVehicle',JSON.stringify({}));
});

$(document).on('click', '.btn.comprar', function(){
	let $el = $(this);
	if($el) {
		$.post('http://vrp_factionsgarages/buyCar',JSON.stringify({
			nome: $el.attr('data-carro-name'),
			preco: $el.attr('data-carro-price'),
			facName: globalFac,
		}));
	}
});