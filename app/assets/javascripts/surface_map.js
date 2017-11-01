// Customized scale control for surface.
L.Control.SurfaceScale = L.Control.Scale.extend({
  options: L.Util.extend({}, L.Control.Scale.prototype.options, { length: undefined }),
  _updateMetric: function(maxMeters) {
    var map = this._map,
	pixelsPerMeter = this.options.maxWidth / (maxMeters * map.getZoomScale(map.getZoom(), 0)),
	microMetersPerPixel = this.options.length / map.getSize().x,
	rate = pixelsPerMeter * microMetersPerPixel,
	meters = this._getRoundNum(maxMeters * rate),
	label = meters < 1000 ? meters + ' μm' : (meters / 1000) + ' mm';
    this._updateScale(this._mScale, label, meters / rate / maxMeters);
  }
});
L.control.surfaceScale = function(options) {
  return new L.Control.SurfaceScale(options);
};


// Customized marker for spot.
L.circleMarker.spot = function(spot, options) {
  var options = L.Util.extend({}, { color: 'red', fillColor: '#f03', fillOpacity: 0.5, radius: 3 }, options),
      marker = new L.circleMarker([-spot.y, spot.x], options);
  marker.on('click', function() {
    var latlng = this.getLatLng(),
        link = '<a href=/records/' + spot.id + '>' + spot.name + '</a><br/>';
    this.bindPopup(link + "x: " + latlng.lng.toFixed(2) + "<br />y: " + -latlng.lat.toFixed(2)).openPopup();
  });
  return marker;
};


// Radius control for Circle.
L.Control.Radius = L.Control.extend({
  initialize: function (layerGroup, options) {
    this._layerGroup = layerGroup;
    L.Util.setOptions(this, options);
  },
  onAdd: function(map) {
    var layerGroup = this._layerGroup,
	div = L.DomUtil.create('div', 'leaflet-control-layers'),
        range = L.DomUtil.create('input');
    range.type = 'range';
    range.min = 1;
    range.max = 10;
    range.value = 3;
    range.style = 'width:60px;margin:3px;';
    div.appendChild(range);
    L.DomEvent.on(range, 'change', function() {
      layerGroup.eachLayer(function(layer) {
	layer.setRadius(range.value);
      });
    });
    L.DomEvent.on(range, 'input', function() {
      layerGroup.eachLayer(function(layer) {
	layer.setRadius(range.value);
      });
    });
    L.DomEvent.on(range, 'mouseenter', function(e) {
      map.dragging.disable()
    });
    L.DomEvent.on(range, 'mouseleave', function(e) {
      map.dragging.enable();
    });
    return div;
  }
});
L.control.radius = function(layerGroup, options) {
  return new L.Control.Radius(layerGroup, options);
};


// Customized layer group for spots.
L.layerGroup.spots = function(spots) {
  var group = L.layerGroup();
  for(spot of spots) {
    L.circleMarker.spot(spot).addTo(group);
  }
  return group;
};


// Customized layer group for grid.
L.layerGroup.grid = function(map) {
  var group = L.layerGroup();
  for (y = 0; y <= map.getSize().y; y += 20) {
    var left = map.unproject([0, y], 0),
	right = map.unproject([map.getSize().x, y]);
    L.polyline([left, right], { color: 'red', weight: 1, opacity: 0.5 }).addTo(group);
  }
  for (x = 0; x <= map.getSize().x; x += 20) {
    var top = map.unproject([x, 0], 0),
	bottom = map.unproject([x, map.getSize().y]);
    L.polyline([top, bottom], { color: 'red', weight: 1, opacity: 0.5 }).addTo(group);
  }
  return group;
};


function initSurfaceMap() {
  var div = document.getElementById("surface-map");
  var radiusSelect = document.getElementById("spot-radius");
  var baseUrl = div.dataset.baseUrl;
  var global_id = div.dataset.globalId;
  var length = parseFloat(div.dataset.length);
  var attachment_files = JSON.parse(div.dataset.attachmentFiles);
  var spots = JSON.parse(div.dataset.spots);
  var layers = [];
  var baseMaps = {};
  var overlayMaps = {};
  var zoom = 1;

  var first = true;
  for(name in attachment_files) {
    var id = attachment_files[name];
    var layer = L.tileLayer(baseUrl + global_id + '/' + id + '/{z}/{x}_{y}.png', { attribution: 'Map data &copy' });
    layers.push(layer);
    if (first) {
      baseMaps[name] = layer;
      first = false;
    } else {
      overlayMaps[name] = layer;
    }
  }

  var map = L.map('surface-map', {
    maxZoom: 8,
    minZoom: 0,
    crs: L.CRS.Simple,
    layers: layers
  });

  var spotsLayer = L.layerGroup.spots(spots);
  map.addLayer(spotsLayer);

  overlayMaps['grid'] = L.layerGroup.grid(map);

  L.control.radius(spotsLayer, {position: 'bottomright'}).addTo(map);

  L.control.surfaceScale({ imperial: false, length: length }).addTo(map);

  L.control.layers(baseMaps, overlayMaps).addTo(map);

  map.setView(map.unproject([map.getSize().x / 2, map.getSize().y / 2], 0), zoom);
}