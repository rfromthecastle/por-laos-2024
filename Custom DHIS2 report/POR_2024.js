/**
This app to present maps for POR 2024
Developer: Truong - CHAI
Date: Nov 2024
**/

var ou = "";
var allOrgUnit = [];
var allHFPointCoordinate = [];
var allOrgUnit_ID_arr = [];

var laos_coordinates = [];
var voronoi_highmap_data;
var district_geojson_map;

$( document ).ready( function(){
	const parentContainer = window.parent.document.querySelector('.container');
	if (parentContainer) {
		parentContainer.style.width = '100%';
	}	
	const dis1_data = dis_data.map(item => {
		return {
			dis_code: item.dis_code,
			stats: item.dist_to_air_int,
			score: parseFloat(item.dist_to_air_int_score)
		};
	});
	
	const dis2_data = dis_data.map(item => {
		return {
			dis_code: item.dis_code,
			stats: item.dist_to_air_med,
			score: parseFloat(item.dist_to_air_med_score)
		};
	});		
	
	const dis3_data = dis_data.map(item => {
		return {
			dis_code: item.dis_code,
			stats: item.dist_to_air_dom,
			score: parseFloat(item.dist_to_air_dom_score)
		};
	});		
	
	const dis4_data = dis_data.map(item => {
		return {
			dis_code: item.dis_code,
			stats: item.dist_to_rail,
			score: parseFloat(item.dist_to_rail_score)
		};
	});		
	
	const dis5_data = dis_data.map(item => {
		return {
			dis_code: item.dis_code,
			stats: item.dist_to_cam,
			score: parseFloat(item.dist_to_cam_score)
		};
	});	

	const dis6_data = dis_data.map(item => {
		return {
			dis_code: item.dis_code,
			stats: item.dist_to_myanmar,
			score: parseFloat(item.dist_to_myanmar_score)
		};
	});		
	
	receptivity_data = [];
	receptivity_strata_data = [];
	
	temp_data.forEach((d, i) => {
		val = d.score;
		val += humidity_data.find(obj => obj.dis_code === d.dis_code).score;
		val += rainfall_data.find(obj => obj.dis_code === d.dis_code).score;
		val += tree_coverage_data.find(obj => obj.dis_code === d.dis_code).score;
		val += swb_6months_data.find(obj => obj.dis_code === d.dis_code).score;
		val += alt_data.find(obj => obj.dis_code === d.dis_code).score;
		
		find_case = case_data.find(obj => obj.dis_code === d.dis_code);
		if(find_case != undefined)
			val += case_data.find(obj => obj.dis_code === d.dis_code).score;
		
		receptivity_data.push({'dis_code': d.dis_code, 'stats': val, 'score': val});
		
		strata_score = 1;
		if(val >=17)
			strata_score = 4;
		else if(val >=14)
			strata_score = 3;
		else if(val >=12)
			strata_score = 2;
		
		receptivity_strata_data.push({'dis_code': d.dis_code, 'stats': val, 'score': strata_score});
	});
	//console.log(receptivity_data);
	
	vulnerability_data = [];
	vulnerability_strata_data = [];
	
	dis1_data.forEach((d, i) => {
		val = d.score;
		val += dis2_data.find(obj => obj.dis_code === d.dis_code).score;
		val += dis3_data.find(obj => obj.dis_code === d.dis_code).score;
		val += dis4_data.find(obj => obj.dis_code === d.dis_code).score;
		val += dis5_data.find(obj => obj.dis_code === d.dis_code).score;
		val += dis6_data.find(obj => obj.dis_code === d.dis_code).score;
		val += pop_data.find(obj => obj.dis_code === d.dis_code).score;
		
		vulnerability_data.push({'dis_code': d.dis_code, 'stats': val, 'score': val});
		
		strata_score = 1;
		if(val >=8)
			strata_score = 4;
		else if(val >=6)
			strata_score = 3;
		else if(val >=4)
			strata_score = 2;
		
		vulnerability_strata_data.push({'dis_code': d.dis_code, 'stats': val, 'score': strata_score});		
	});	
	
	combined_data = [];
	combined_strata_data = [];
	
	vulnerability_data.forEach((d, i) => {
		val = d.score;
		val += receptivity_data.find(obj => obj.dis_code === d.dis_code).score;
		
		combined_data.push({'dis_code': d.dis_code, 'stats': val, 'score': val});
		
		strata_score = 1;
		if(val >=22)
			strata_score = 4;
		else if(val >=19)
			strata_score = 3;
		else if(val >=17)
			strata_score = 2;
		
		combined_strata_data.push({'dis_code': d.dis_code, 'stats': val, 'score': strata_score});			
	});
	
	temp_dataClasses = [{
		from: 1,
		to: 1,
		color: '#81817D',
		name: '< 50% days 20-30°C'
	}, {
		from: 2,
		to: 2,
		color: '#FEA500',
		name: '50 - 80% days 20-30°C'
	}, {
		from: 3,
		to: 3,
		color: '#8C0001',
		name: '≥ 80% days 20-30°C'
	}];
	
	humidity_dataClasses = [
		{
			from: 1,
			to: 1,
			color: '#FFFEE0',
			name: '< 50% of days 70-100%'
		}, {
			from: 2,
			to: 2,
			color: '#DDA0DC',
			name: '50 - 80% of days 70-100%'
		}, {
			from: 3,
			to: 3,
			color: '#8C0A51',
			name: '≥ 80% of days 70-100%'
		}];
		
	rainfall_dataClasses = [
		{
			from: 1,
			to: 1,
			color: '#B4DFE9',
			name: 'Weekly median of <8mm'
		}, {
			from: 2,
			to: 2,
			color: '#5DACEE',
			name: 'Weekly median of ≥8 and <16mm'
		}, {
			from: 3,
			to: 3,
			color: '#0000C0',
			name: 'Weekly median of ≥16 mm'
		}];

	forestcover_dataClasses = [
		{
			from: 1,
			to: 1,
			color: '#C1FFC0',
			name: '< 40% forest cover'
		}, {
			from: 2,
			to: 2,
			color: '#9BCD9A',
			name: '≥ 40% and <75% forest cover'
		}, {
			from: 3,
			to: 3,
			color: '#006401',
			name: '≥ 75% forest cover'
		}];
		
	altitude_dataClasses = [
		{
			from: 1,
			to: 1,
			color: '#C1FFC0',
			name: 'Mean ≥ 2000m'
		}, {
			from: 2,
			to: 2,
			color: '#CDC773',
			name: 'Mean ≥ 500m and <2000m'
		}, {
			from: 3,
			to: 3,
			color: '#9BCD9A',
			name: 'Mean < 500m'
		}];
		
	swb_dataClasses = [
		{
			from: 1,
			to: 1,
			color: '#B4DFE9',
			name: '≥1%'
		}, {
			from: 2,
			to: 2,
			color: '#5DACEE',
			name: '≥ 0.5% and <1%'
		}, {
			from: 3,
			to: 3,
			color: '#0000C0',
			name: '≥1%'
		}];
		
	pop_dataClasses = [{
		from: 1,
		to: 1,
		color: '#FFFEE0',
		name: '< 50.000 people'
	}, {
		from: 2,
		to: 2,
		color: '#FEA500',
		name: '50.000 - 100.000 people'
	}, {
		from: 3,
		to: 3,
		color: '#8C0001',
		name: '≥ 100.000 people'
	}];	
	
	dis1_dataClasses = [{
		from: 1,
		to: 1,
		color: '#FFFEE0',
		name: '> 50 km'
	}, {
		from: 2,
		to: 2,
		color: '#FEA500',
		name: '21 - 50 km'
	}, {
		from: 3,
		to: 3,
		color: '#8C0001',
		name: '<20 km'
	}];	
	
	dis2_dataClasses = [{
		from: 0.5,
		to: 0.5,
		color: '#FFFEE0',
		name: '> 50 km'
	}, {
		from: 1,
		to: 1,
		color: '#FEA500',
		name: '21 - 50 km'
	}, {
		from: 1.5,
		to: 1.5,
		color: '#8C0001',
		name: '<20 km'
	}];	
	
	dis3_dataClasses = [{
		from: 0.25,
		to: 0.25,
		color: '#FFFEE0',
		name: '> 50 km'
	}, {
		from: 0.5,
		to: 0.5,
		color: '#FEA500',
		name: '21 - 50 km'
	}, {
		from: 0.75,
		to: 0.75,
		color: '#8C0001',
		name: '<20 km'
	}];		
	
	dis4_dataClasses = [{
		from: 0.25,
		to: 0.25,
		color: '#FFFEE0',
		name: '> 50 km'
	}, {
		from: 0.5,
		to: 0.5,
		color: '#FEA500',
		name: '21 - 50 km'
	}, {
		from: 0.75,
		to: 0.75,
		color: '#8C0001',
		name: '<20 km'
	}];	

	dis5_dataClasses = [{
		from: 0.5,
		to: 0.5,
		color: '#FFFEE0',
		name: '> 50 km'
	}, {
		from: 1,
		to: 1,
		color: '#FEA500',
		name: '21 - 50 km'
	}, {
		from: 1.5,
		to: 1.5,
		color: '#8C0001',
		name: '<20 km'
	}];	
	
	dis6_dataClasses = [{
		from: 1,
		to: 1,
		color: '#FFFEE0',
		name: '> 50 km'
	}, {
		from: 2,
		to: 2,
		color: '#FEA500',
		name: '21 - 50 km'
	}, {
		from: 3,
		to: 3,
		color: '#8C0001',
		name: '<20 km'
	}];		
		
	case_dataClasses = [{
		from: 1,
		to: 1,
		color: '#FFFEE0',
		name: '> 100 cases'
	}, {
		from: 2,
		to: 2,
		color: '#FEA500',
		name: '50 - 99 cases'
	}, {
		from: 3,
		to: 3,
		color: '#8C0001',
		name: '<50 cases'
	}];		
		
	comp_rec_dataClasses = [{
		from: 0,
		to: 10,
		color: '#f5e8d2',
		name: '< 10'
	}, {
		from: 10,
		to: 12.5,
		color: '#d2b48c',
		name: '10 - 12.5'
	}, {
		from: 12.5,
		to: 15.0,
		color: '#c19a6b',
		name: '12.5 - 15'
	}, {
		from: 15.0,
		to: 17.5,
		color: '#a0522d',
		name: '15 - 17.5'
	}, {
		from: 17.5,
		color: '#8b4513',
		name: '>17.5'
	}];		
		
	comp_vul_dataClasses = [{
		from: 0,
		to: 4,
		color: '#f5e8d2',
		name: '< 4'
	}, {
		from: 4,
		to: 6,
		color: '#d2b48c',
		name: '4 - 6'
	}, {
		from: 6,
		to: 8,
		color: '#c19a6b',
		name: '6 - 8'
	}, {
		from: 8,
		to: 10,
		color: '#a0522d',
		name: '8 - 10'
	}, {
		from: 10,
		color: '#8b4513',
		name: '>10'
	}];		
	
	comp_com_dataClasses = [{
		from: 0,
		to: 16,
		color: '#f5e8d2',
		name: '< 16'
	}, {
		from: 16,
		to: 18,
		color: '#d2b48c',
		name: '16 - 18'
	}, {
		from: 18,
		to: 20,
		color: '#c19a6b',
		name: '18 - 20'
	}, {
		from: 20,
		to: 22,
		color: '#a0522d',
		name: '20 - 22'
	}, {
		from: 22,
		color: '#8b4513',
		name: '>22'
	}];		
			
	rec_strata_dataClasses = [{
		from: 1,
		to: 1,
		color: '#F2F2F2',
		name: 'score <12'
	}, {
		from: 2,
		to: 2,
		color: '#FFFF00',
		name: 'score 12 - 14'
	}, {
		from: 3,
		to: 3,
		color: '#FEA500',
		name: 'score 14 - 16'
	}, {
		from: 4,
		to: 4,
		color: '#850A0A',
		name: 'score ≥17'
	}];
	
	vul_strata_dataClasses = [{
		from: 1,
		to: 1,
		color: '#F2F2F2',
		name: 'score <4'
	}, {
		from: 2,
		to: 2,
		color: '#FFFF00',
		name: 'score 4 - 5'
	}, {
		from: 3,
		to: 3,
		color: '#FEA500',
		name: 'score 6 - 7'
	}, {
		from: 4,
		to: 4,
		color: '#850A0A',
		name: 'score ≥8'
	}];
	
	com_strata_dataClasses = [{
		from: 1,
		to: 1,
		color: '#F2F2F2',
		name: 'score <17'
	}, {
		from: 2,
		to: 2,
		color: '#FFFF00',
		name: 'score 17 - 18'
	}, {
		from: 3,
		to: 3,
		color: '#FEA500',
		name: 'score 19 - 20'
	}, {
		from: 4,
		to: 4,
		color: '#850A0A',
		name: 'score ≥22'
	}];	
				
			
	list_map = [
		['temp', 'Temprature', map_data, temp_data, 'map_temp', 'Laos Temprature 2021 - 2023', temp_dataClasses, '#table_temp'],
		['humidity', 'Humidity', map_data, humidity_data, 'map_humidity', 'Laos Humidity 2021 - 2023', humidity_dataClasses, '#table_humidity'],
		['rainfall', 'Rainfall', map_data, rainfall_data, 'map_rainfall', 'Laos Rainfall 2021 - 2023', rainfall_dataClasses, '#table_rainfall'],
		['forestcover', 'Forest cover', map_data, tree_coverage_data, 'map_forestcover', 'Laos Forest cover 2021 - 2023', forestcover_dataClasses, '#table_forestcover'],
		['altitude', 'Altitude', map_data, alt_data, 'map_altitude', 'Laos Altitude', altitude_dataClasses, '#table_altitude'],
		['swb', 'Seasonal water bodies', map_data, swb_6months_data, 'map_swb', 'Seasonal water bodies 2021 - 2023', swb_dataClasses, '#table_swb'],
		
		['dis1', 'Distance to nearest international airports', map_data, dis1_data, 'map_dis1', 'Distance to nearest international airports', dis1_dataClasses, '#table_dis1'],
		['dis2', 'Distance to nearest intermediate airports', map_data, dis2_data, 'map_dis2', 'Distance to nearest intermediate airports', dis2_dataClasses, '#table_dis2'],
		['dis3', 'Distance to nearest domestic airports', map_data, dis3_data, 'map_dis3', 'Distance to nearest domestic airports', dis3_dataClasses, '#table_dis3'],
		['dis4', 'Distance to nearest railway station', map_data, dis4_data, 'map_dis4', 'Distance to nearest railway station', dis4_dataClasses, '#table_dis4'],
		['dis5', 'Distance to Cambodia', map_data, dis5_data, 'map_dis5', 'Distance to Cambodia', dis5_dataClasses, '#table_dis5'],
		['dis6', 'Distance to Myanmar', map_data, dis6_data, 'map_dis6', 'Distance to Myanmar', dis6_dataClasses, '#table_dis6'],		

		['case', 'Number of cases (2017-2023)', map_data, case_data, 'map_case', 'Laos number of malaria cases 2017 - 2023', case_dataClasses, '#table_case'],
		
		['population', 'Population (2023)', map_data, pop_data, 'map_population', 'Laos Population 2023', pop_dataClasses, '#table_population'],
		['comp_rec', 'Comparison of matrices (Receptivity)', map_data, receptivity_data, 'map_comp_rec', 'Comparison of matrices (Receptivity)', comp_rec_dataClasses, '#table_comp_rec'],
		['comp_vul', 'Comparison of matrices (Vulnerability)', map_data, vulnerability_data, 'map_comp_vul', 'Comparison of matrices (Vulnerability)', comp_vul_dataClasses, '#table_comp_vul'],
		['comp_com', 'Comparison of matrices (Combined Receptivity and Vulnerability)', map_data, combined_data, 'map_comp_com', 'Comparison of matrices (Combined Receptivity and Vulnerability)', comp_com_dataClasses, '#table_comp_com'],
		
		['comp_rec2', 'Comparison of matrices based on strata (1-4) (Receptivity)', map_data, receptivity_strata_data, 'map_comp_rec2', 'Comparison of matrices based on strata (1-4) (Receptivity)', rec_strata_dataClasses, '#table_comp_rec2'],
		['comp_vul2', 'Comparison of matrices based on strata (1-4) (Vulnerability)', map_data, vulnerability_strata_data, 'map_comp_vul2', 'Comparison of matrices based on strata (1-4) (Vulnerability)', vul_strata_dataClasses, '#table_comp_vul2'],
		['comp_com2', 'Comparison of matrices based on strata (1-4) (Combined Receptivity and Vulnerability)', map_data, combined_strata_data, 'map_comp_com2', 'Comparison of matrices based on strata (1-4) (Combined Receptivity and Vulnerability)', com_strata_dataClasses, '#table_comp_com2']
	];
	
	list_map.forEach((d, i) => {
		is_active = '';
		is_checked = '';
		if(i == 0){
			is_active = ' active';
			is_checked = 'checked';
		}
		
		$("#container").append("<div class='map-container"+ is_active +"' id='map_" + d[0] + "-container'><div id='map_" + d[0] + "'></div><table id='table_" + d[0] + "' class='display' width='100%'></table></div>");
		$("#menu").append("<div class='form-check'><input class='form-check-input' type='checkbox' name='dashboardItem' id='map_" + d[0] + "_select' value='map_" + d[0] + "' "+ is_checked +"><label class='form-check-label' for='map_" + d[0] + "'>" + d[1] + "</label></div>");
		
		if(d.length > 2)
			generateMap(d[2], d[3], d[4], d[5], d[6], d[7]);
		
		console.log(i);
	});
	
	document.querySelectorAll('input[name="dashboardItem"]').forEach(checkbox => {
		// Add event listener to the checkbox
		checkbox.addEventListener('change', function () {
			const selectedContainer = document.getElementById(this.value + '-container');

			if (this.checked) {
				// Show the corresponding container
				if (selectedContainer) {
					selectedContainer.classList.add('active');
				}
			} else {
				// Hide the corresponding container
				if (selectedContainer) {
					selectedContainer.classList.remove('active');
				}
			}
		});

		// Add event listener to the label associated with the checkbox
		const label = document.querySelector(`label[for="${checkbox.id}"]`);
		if (label) {
			label.addEventListener('click', function () {
				// Toggle the checkbox manually
				checkbox.checked = !checkbox.checked;

				// Trigger the change event manually to ensure proper handling
				checkbox.dispatchEvent(new Event('change'));
			});
		}
	});
	
});

function getGeoJson(){
	$.get("../../../api/organisationUnits.geojson?level=3", function(json) {
		data = Highcharts.geojson(json);
		
		data.forEach((d, i) => {
			if(d.properties.code != undefined){
				code = d.properties.code.replace('ASILAO0','LA');
				code = code.slice(0, 4) + code.slice(5);
				d.properties.code = code;
			}
		});
		console.log(data);	
	});
}

function create_voronoi(){
	//laos_geometry = Highcharts.maps["countries/la/la-all_province"].features[0].geometry;
	laos_coordinates = Highcharts.maps["countries/la/la-all_province"].features[0].geometry.coordinates;	
	
	// Example Laos boundary (GeoJSON-like format)
	const laosBoundary = {
		type: "MultiPolygon",
		coordinates: laos_coordinates
	};
		
	console.log('---3---');
	console.log(new Date().toLocaleString());

	// Generate Delaunay triangulation and Voronoi diagram
	const delaunay = d3.Delaunay.from(allHFPointCoordinate);
	const voronoi = delaunay.voronoi();

	// Convert Laos boundary to Turf.js polygon
	const multiPolygonBoundary = turf.multiPolygon(laosBoundary.coordinates);
	const clippedPolygons = [];
	
	for (let i = 0; i < allHFPointCoordinate.length; i++) {
		// Get the Voronoi cell for each point
		const cell = voronoi.cellPolygon(i);
		if (cell) {
			// Convert the Voronoi cell to a Turf.js polygon
			const voronoiPolygon = turf.polygon([cell]);

			// Clip the Voronoi cell to the Laos boundary
			const clipped = turf.intersect(voronoiPolygon, multiPolygonBoundary);
			if (clipped) {
				clippedPolygons.push(clipped);
			}
		}
	}
		
	// Convert the data to JSON
	const dataStr = JSON.stringify(clippedPolygons, null, 2); // Pretty print with 2 spaces
	const blob = new Blob([dataStr], { type: "application/json" });

	// Create a download link
	const a = document.createElement("a");
	a.href = URL.createObjectURL(blob);
	a.download = "highchartsData.json";
	a.text = "Download";
	document.body.appendChild(a);
}

// Function to flip coordinates horizontally
function flipCoordinatesHorizontally(coordinates) {
    return coordinates.map(([x, y]) => [-x, y]); // Negate the X-coordinate
}

function generateMap(map_data, temp_data, container, graph_title, dataClasses, table_container){
	var dataSet = [];
	map_data.forEach((d, i) => {
		if(d.properties.code != undefined){
			temp_data.forEach((d1, i1) => {
				if(d1.dis_code == d.properties.code){
					d.value = d1.score;
					d.stats = d1.stats;
					d.name = d.properties.name;
					dataSet.push([i + 1, d.name, d.properties.code, d1.stats, d1.score]);
				}
			});			
		}
	});
	
	Highcharts.mapChart(container, {
		chart: {
			type: 'map',
			
		},
		title: {
			text: graph_title
		},
		colorAxis:{
			dataClasses: dataClasses
		},
		mapNavigation: {
			enabled: true,
			buttonOptions: {
				verticalAlign: 'bottom',
				horizontalAlign: 'right',
			}
		},		
		tooltip: {
            headerFormat: '',
            pointFormat: '<b>Name: {point.name}</b></br>Stats: {point.stats}</br>Score: {point.value}'
        },		
		plotOptions: {
			map: {
				states: {
					hover: {
						color: '#EEDD66'
					}
				}
			},
			mappoint: {
				marker: {
					lineWidth: 1,
					lineColor: '#000',
					symbol: 'mapmarker',
					radius: 8
				},
				dataLabels: {
					enabled: false
				}
			},
			series: {
				states: {
					inactive: {
						opacity: 1
					}
				}
			}			
		},
		legend: {
            align: 'left',
            verticalAlign: 'middle',
            floating: false,
            layout: 'vertical',
            valueDecimals: 0,
            backgroundColor: 'rgba(255,255,255,0.9)',
            padding: 12,
            itemMarginTop: 0,
            itemMarginBottom: 0,
            symbolRadius: 0,
            symbolHeight: 14,
            symbolWidth: 24
		},
		credits: {
			enabled: false
		},		
		series: [
			{
				data: map_data,
				enableMouseTracking: true,
				showInLegend: false,
				zIndex: 3,
				lineWidth: 0.5, // Thinner lines
				borderColor: '#000',
				borderWidth: 0.3,
				dataLabels: {
					enabled: true,
					format: '{false.properties.name}',
					zIndex: 1,
				},
			}
		]
	});

	generateTable(dataSet, table_container);
}

function generateTable(dataset, table_container){
	strHeader = "";
	strHeader += "<thead>";
	strHeader += "<tr>";
	strHeader += "	<th>No</th>";
	strHeader += "	<th>District name</th>";
	strHeader += "	<th>District code</th>";
	strHeader += "	<th>Stats</th>";
	strHeader += "	<th>Score</th>";
	strHeader += "</tr>";
	strHeader += "</thead>";
	
	$(table_container).html(strHeader);
	var table = $(table_container).DataTable({
		data: dataset,
		order: [],	
		"rowCallback": function( row, data, index ) {
			if (data[0] === "Total") {  // Assuming the "Total" label is in the first column
                $(row).addClass('no-sort');
            }
            if ($(row).hasClass('no-sort')) {
                $(row).attr('data-order', 'no-sort'); // Tag row for no sorting
            }
        },
		"drawCallback": function(settings) {
            var api = this.api();
            var rows = api.rows().nodes();
            // Move the "Total" row to the end after sorting
            $(rows).each(function() {
                if ($(this).hasClass('no-sort')) {
                    $(this).appendTo($(this).parent());
                }
            });
            
            // Calculate the maximum value, excluding the "Total" row and the last two columns
            var maxVal = -Infinity;
            api.rows({ page: 'current' }).every(function(rowIdx, tableLoop, rowLoop) {
                var rowData = this.data();
                if (!$(this.node()).hasClass('no-sort')) {
                    api.cells(rowIdx, 4).every(function(cellIdx) {
                        var value = parseFloat(String(this.data()).replace(/[^0-9.-]+/g, ""));
                        if (!isNaN(value) && value !== 0) {
                            maxVal = Math.max(maxVal, value);
                        }
                    });
                }
            });
			
            // Apply heatmap coloring
            api.cells().every(function() {
                var cell = this.node();
                var value = parseFloat($(cell).text().replace(/[^0-9.-]+/g,"")); // Extract numerical value
				var columnIndex = this.index().column;
				var totalColumns = api.columns().count();

                // Exclude cells in the "Total" row from heat coloring
                if (!isNaN(value) && value != 0 && !$(cell).closest('tr').hasClass('no-sort') && columnIndex > 3) {
                    $(cell).css('background-color', getHeatColor(value, maxVal));
                }
            });

        },
        "columnDefs": [{
            "targets": 'no-sort',
            "orderable": false,
        }],
		destroy: true,
		paging: false,
		scrollCollapse: true,
		scrollX: true,
		scrollY: 500,
		layout: {
			topStart: {
				buttons: ['copy', 'csv', 'excel']
			}
		}
	});	
		
    // Function to determine the heatmap color based on the value
    function getHeatColor(value, max) {
        // Customize the color scale as needed
        var min = 0;   // Minimum value
        var max = max; // Maximum value
		
		//console.log(max);
        // Normalize the value between 0 and 1
        var normalizedValue = (value - min) / (max - min);
		//console.log(normalizedValue);
        // Apply colors based on the normalized value in 5 ranges
        if (normalizedValue <= 0.34) {
            return 'rgb(255, 230, 230)'; // Very light red
        } else if (normalizedValue <= 0.67) {
            return 'rgb(255, 150, 150)'; // Medium red
        } else if (normalizedValue <= 1) {
            return 'rgb(255, 50, 50)'; // Dark red
        }
    }	

	//table.columns.adjust().draw();
}

function generateMapHFVoronoi(){
	// Instantiate the map
	let separators = Highcharts.geojson(Highcharts.maps['countries/la/la-all_province']);
	let currentlevel = 0;
	let mapKeyLv1 = "";
	let mapKeyLv2 = "";
	var situation = 0;
	districtName = "";
	//url = "../api/38/analytics?dimension=dx:i01fxHSZQ7t;CNkJFZWuB9c,pe:"+reportYear+",ou:"+orgUnit+";LEVEL-d4UXL51EVXm&displayProperty=NAME&includeNumDen=true&skipMeta=true&skipData=false&paging=false";
	arrDataMap = [];

	//laos_geometry = Highcharts.maps["countries/la/la-all_province"].features[0].geometry;
	//laos_coordinates = [laos_geometry.coordinates[0][0].concat(laos_geometry.coordinates[1][0].concat(laos_geometry.coordinates[2][0]))];	
	
	// Example Laos boundary (GeoJSON-like format)
	const laosBoundary = {
		type: "Polygon",
		coordinates: laos_coordinates
	};
	let data = Highcharts.geojson(voronoi_data);
	
	data.forEach((d, i) => {
		d.rainfall = 200*Math.random();
		d.value = 200*Math.random();
	});
	
	console.log(data);
	
	Highcharts.mapChart('map_temp', {
		chart: {
			type: 'map',
			
		},
		title: {
			text: 'Voronoi Diagram Clipped to Laos Boundary'
		},
		colorAxis: {
			min: 100, // Minimum rainfall value
			max: 300, // Maximum rainfall value
			stops: [
				[0, '#0000FF'], // Blue for low rainfall
				[0.5, '#FFFF00'], // Yellow for medium rainfall
				[1, '#FF0000']  // Red for high rainfall
			]
		},
		xAxis: {
			reversed: true // Reverse the X-axis
		},
		yAxis: {
			reversed: true // Reverse the Y-axis
		},
		mapNavigation: {
			enabled: true,
			buttonOptions: {
				verticalAlign: 'bottom',
				horizontalAlign: 'right',
			}
		},		
		plotOptions: {
			map: {
				states: {
					hover: {
						color: '#EEDD66'
					}
				}
			},
			mappoint: {
				marker: {
					lineWidth: 1,
					lineColor: '#000',
					symbol: 'mapmarker',
					radius: 8
				},
				dataLabels: {
					enabled: false
				}
			},
			series: {
				states: {
					inactive: {
						opacity: 1
					}
				}
			}			
		},
		legend: {
			align: 'center',
			verticalAlign: 'bottom',
			floating: false,
			layout: 'horizontal',
			valueDecimals: 0,
			backgroundColor: 'rgba(255,255,255,0.9)',
			padding: 12,
			itemMarginTop: 0,
			itemMarginBottom: 0,
			symbolRadius: 0,
			symbolHeight: 14,
			symbolWidth: 24
		},
		credits: {
			enabled: false
		},		
		series: [
			{
				type: 'map',
				data: data,
				joinBy: ['id', 'name'],
				enableMouseTracking: false,
				showInLegend: false,
				zIndex: 3,
				lineWidth: 0.5, // Thinner lines
				borderColor: '#000',
				borderWidth: 0.3,
				tooltip: {
					pointFormat: 'ID: {point.properties.id} mm'
				}
			},
			{
				type: 'mappoint',
				name: 'Health Facilities',
				data: allHFPointCoordinate.map(([id, name, lon, lat], index) => ({
					id: id,
					name: name, // Optional point name
					x: lon, // Longitude
					y: lat  // Latitude
				})),
				marker: {
					symbol: 'point',
					radius: 0.5, // Small red point
					fillColor: 'red',
					lineWidth: 0 // Removes the black border
				},
				tooltip: {
					pointFormat: 'ID: {point.id}</br> Name: {point.name}</br> Longitude: {point.x}, Latitude: {point.y}' // Tooltip format
				},
				zIndex: 4,
			},
			{
				name: 'rainfall',
				joinBy: 'id',
				keys: ['id', 'value'],
				data: [["1", 200], ["2", 300]]
			}
		]
	});
}