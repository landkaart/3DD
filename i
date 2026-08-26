<!doctype html>
<html lang="nl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">

<title>3DBAG adres naar 3D gebouw</title>

<style>
* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  font-family: system-ui, sans-serif;
  background: #111;
  color: #eee;
}

header {
  height: 112px;
  padding: 14px 18px;
  background: #1b1b1b;
  position: relative;
  z-index: 10;
}

h1 {
  font-size: 18px;
  margin: 0 0 10px;
}

.row {
  display: flex;
  gap: 8px;
  max-width: 900px;
}

input {
  flex: 1;
  min-width: 0;
  padding: 11px;
  border: 1px solid #555;
  border-radius: 7px;
  background: #222;
  color: #fff;
  font-size: 14px;
}

button {
  padding: 11px 18px;
  border: 0;
  border-radius: 7px;
  cursor: pointer;
  font-weight: 600;
}

button:disabled {
  opacity: .5;
  cursor: wait;
}

#status {
  margin-top: 7px;
  color: #bbb;
  font-size: 13px;
}

#viewer {
  position: relative;
  width: 100%;
  height: calc(100% - 112px);
}

canvas {
  display: block;
}

#info {
  display: none;
  position: absolute;
  right: 16px;
  top: 16px;
  z-index: 5;
  min-width: 280px;
  padding: 14px;
  background: #202020e8;
  border-radius: 9px;
  line-height: 1.5;
  font-size: 13px;
}

#info b {
  display: block;
  margin-bottom: 8px;
  font-size: 15px;
}

#hint {
  position: absolute;
  left: 16px;
  bottom: 16px;
  z-index: 5;
  background: #202020cc;
  padding: 9px 12px;
  border-radius: 7px;
  font-size: 12px;
}

#error {
  display: none;
  position: absolute;
  left: 15px;
  right: 15px;
  top: 122px;
  z-index: 20;
  max-height: 350px;
  overflow: auto;
  padding: 15px;
  background: #351818;
  border: 1px solid #773333;
  border-radius: 8px;
  white-space: pre-wrap;
  font-family: monospace;
  font-size: 12px;
}
</style>
</head>

<body>

<header>

<h1>🇳🇱 3DBAG — adres naar 3D gebouw</h1>

<div class="row">

<input
  id="address"
  value="Stationsweg 1, Leeuwarden"
  placeholder="Bijv. Stationsweg 1, Leeuwarden"
>

<button id="go">
Zoek
</button>

</div>

<div id="status">
Klaar — vul een Nederlands adres in.
</div>

</header>

<div id="error"></div>

<div id="viewer">

<div id="info"></div>

<div id="hint">
Sleep = draaien · scroll = zoomen · klik op gebouw = informatie
</div>

</div>


<script type="importmap">
{
  "imports": {
    "three": "https://cdn.jsdelivr.net/npm/three@0.180.0/build/three.module.js",
    "three/addons/": "https://cdn.jsdelivr.net/npm/three@0.180.0/examples/jsm/"
  }
}
</script>


<script type="module">

import * as THREE from
"https://cdn.jsdelivr.net/npm/three@0.180.0/build/three.module.js";

import {
  OrbitControls
} from
"https://cdn.jsdelivr.net/npm/three@0.180.0/examples/jsm/controls/OrbitControls.js";


/* =========================================================
   ELEMENTEN
========================================================= */

const viewer =
document.getElementById("viewer");

const addressInput =
document.getElementById("address");

const goButton =
document.getElementById("go");

const status =
document.getElementById("status");

const info =
document.getElementById("info");

const errorBox =
document.getElementById("error");


/* =========================================================
   THREE
========================================================= */

const scene =
new THREE.Scene();

scene.background =
new THREE.Color(0x9fb3c8);


const camera =
new THREE.PerspectiveCamera(
  45,
  viewer.clientWidth /
  viewer.clientHeight,
  0.1,
  100000
);

camera.position.set(
  30,
  25,
  30
);


const renderer =
new THREE.WebGLRenderer({
  antialias: true
});

renderer.setPixelRatio(
  Math.min(
    window.devicePixelRatio,
    2
  )
);

renderer.setSize(
  viewer.clientWidth,
  viewer.clientHeight
);

viewer.prepend(
  renderer.domElement
);


const controls =
new OrbitControls(
  camera,
  renderer.domElement
);

controls.enableDamping = true;

controls.dampingFactor = 0.08;


scene.add(
  new THREE.HemisphereLight(
    0xffffff,
    0x555555,
    2
  )
);


const sun =
new THREE.DirectionalLight(
  0xffffff,
  2
);

sun.position.set(
  50,
  80,
  30
);

scene.add(sun);


scene.add(
  new THREE.GridHelper(
    500,
    50,
    0x666666,
    0x888888
  )
);


let model = null;


/* =========================================================
   STATUS
========================================================= */

function setStatus(text) {
  status.textContent = text;
}


/* =========================================================
   ERROR
========================================================= */

function showError(
  message,
  details = null
) {

  console.error(
    message,
    details
  );

  errorBox.style.display =
    "block";

  errorBox.textContent =
    message +
    (
      details
        ? "\n\n" +
          JSON.stringify(
            details,
            null,
            2
          )
        : ""
    );

  setStatus(
    "Fout: " + message
  );
}


/* =========================================================
   JSON OPHALEN
========================================================= */

async function getJson(url) {

  console.log(
    "GET",
    url
  );

  const response =
    await fetch(url);


  const text =
    await response.text();


  if (!response.ok) {

    throw new Error(
      "HTTP " +
      response.status +
      "\n" +
      text.substring(
        0,
        1500
      )
    );
  }


  try {

    return JSON.parse(text);

  } catch {

    throw new Error(
      "Server gaf geen geldige JSON:\n" +
      text.substring(
        0,
        1500
      )
    );
  }
}


/* =========================================================
   1. ADRES → PDOK
========================================================= */

async function geocode(query) {

  setStatus(
    "1/5 Adres zoeken via PDOK…"
  );


  const url =
    "https://api.pdok.nl/bzk/locatieserver/search/v3_1/free" +
    "?q=" +
    encodeURIComponent(query) +
    "&fq=type:adres" +
    "&rows=1";


  const json =
    await getJson(url);


  const docs =
    json.response?.docs || [];


  if (!docs.length) {

    throw new Error(
      "Adres niet gevonden."
    );
  }


  const d =
    docs[0];


  /*
   * PDOK geeft bijvoorbeeld:
   *
   * POINT(5.7955 53.1969)
   */

  const match =
    String(
      d.centroide_ll || ""
    ).match(
      /^POINT\s*\(\s*([+-]?\d+(?:\.\d+)?)\s+([+-]?\d+(?:\.\d+)?)\s*\)$/i
    );


  if (!match) {

    throw new Error(
      "PDOK gaf geen bruikbare coördinaten."
    );
  }


  const lon =
    Number(match[1]);

  const lat =
    Number(match[2]);


  if (
    !Number.isFinite(lon) ||
    !Number.isFinite(lat)
  ) {

    throw new Error(
      "PDOK-coördinaten zijn ongeldig."
    );
  }


  return {
    lon,
    lat,
    label:
      d.weergavenaam ||
      query,
    doc: d
  };
}


/* =========================================================
   2. BAG VERBLIJFSOBJECT
========================================================= */

async function findVerblijfsobject(
  lon,
  lat
) {

  setStatus(
    "2/5 BAG-verblijfsobject zoeken…"
  );


  /*
   * Kleine geografische zoekbox.
   *
   * BELANGRIJK:
   * lon/lat worden eerst gecontroleerd.
   */

  if (
    !Number.isFinite(lon) ||
    !Number.isFinite(lat)
  ) {

    throw new Error(
      "Ongeldige coördinaten voor BAG-query."
    );
  }


  const delta =
    0.0002;


  const bbox =
    [
      lon - delta,
      lat - delta,
      lon + delta,
      lat + delta
    ].join(",");


  const url =
    "https://api.pdok.nl/kadaster/bag/ogc/v2" +
    "/collections/verblijfsobject/items" +
    "?bbox=" +
    encodeURIComponent(bbox) +
    "&limit=100" +
    "&f=json";


  const json =
    await getJson(url);


  const features =
    json.features || [];


  if (!features.length) {

    throw new Error(
      "Geen BAG-verblijfsobject gevonden."
    );
  }


  /*
   * Zoek geografisch het dichtstbijzijnde
   * verblijfsobject.
   */

  let best = null;

  let bestDistance =
    Infinity;


  for (
    const feature
    of features
  ) {

    const c =
      feature.geometry?.coordinates;


    if (
      !Array.isArray(c) ||
      c.length < 2
    ) {

      continue;
    }


    const x =
      Number(c[0]);

    const y =
      Number(c[1]);


    if (
      !Number.isFinite(x) ||
      !Number.isFinite(y)
    ) {

      continue;
    }


    const dx =
      x - lon;

    const dy =
      y - lat;


    const distance =
      dx * dx +
      dy * dy;


    if (
      distance <
      bestDistance
    ) {

      bestDistance =
        distance;

      best =
        feature;
    }
  }


  if (!best) {

    throw new Error(
      "BAG-resultaten hebben geen bruikbare geometrie."
    );
  }


  console.log(
    "BAG verblijfsobject:",
    best
  );


  return best;
}


/* =========================================================
   3. BAG VERBLIJFSOBJECT → PAND
========================================================= */

async function getPand(
  verblijfsobject
) {

  setStatus(
    "3/5 BAG-pand bepalen…"
  );


  const properties =
    verblijfsobject.properties ||
    {};


  /*
   * DIT IS DE CRUCIALE REGEL:
   *
   * BAG levert de relatie als property
   * met letterlijk de naam "pand.href".
   */

  const pandHrefs =
    properties["pand.href"];


  if (
    !Array.isArray(pandHrefs) ||
    pandHrefs.length === 0
  ) {

    throw new Error(
      "BAG-verblijfsobject heeft geen pand.href."
    );
  }


  const pandUrl =
    pandHrefs[0];


  if (
    typeof pandUrl !== "string" ||
    !pandUrl.startsWith(
      "https://api.pdok.nl/"
    )
  ) {

    throw new Error(
      "Ongeldige BAG pand.href:\n" +
      String(pandUrl)
    );
  }


  console.log(
    "BAG pand URL:",
    pandUrl
  );


  const pand =
    await getJson(
      pandUrl
    );


  const pandProperties =
    pand.properties || {};


  /*
   * Dit is het nummer dat 3DBAG wil hebben.
   *
   * Voor jouw voorbeeld:
   *
   * 0080100010091833
   */

  const identificatie =
    pandProperties.identificatie;


  if (
    !identificatie
  ) {

    throw new Error(
      "BAG-pand heeft geen identificatie."
    );
  }


  console.log(
    "BAG pand identificatie:",
    identificatie
  );


  return {
    feature: pand,
    identificatie:
      String(identificatie)
  };
}


/* =========================================================
   4. 3DBAG
========================================================= */

async function get3DBAG(
  bagPandId
) {

  setStatus(
    "4/5 3DBAG 3D-model ophalen…"
  );


  /*
   * 3DBAG verwacht de BAG identificatie,
   * niet de UUID uit de BAG OGC URL.
   *
   * Dus:
   *
   * 0080100010091833
   *
   * wordt:
   *
   * NL.IMBAG.Pand.0080100010091833
   */

  const clean =
    String(bagPandId)
      .replace(
        /^NL\.IMBAG\.Pand\./i,
        ""
      );


  const threeDbagId =
    "NL.IMBAG.Pand." +
    clean;


  const url =
    "https://api.3dbag.nl" +
    "/collections/pand/items/" +
    encodeURIComponent(
      threeDbagId
    );


  console.log(
    "3DBAG URL:",
    url
  );


  const data =
    await getJson(
      url
    );


  if (!data) {

    throw new Error(
      "3DBAG gaf geen data terug."
    );
  }


  if (
    !data.feature &&
    !data.features
  ) {

    throw new Error(
      "3DBAG-response bevat geen feature."
    );
  }


  return data;
}


/* =========================================================
   5. CITYJSONFEATURE RENDEREN
========================================================= */

function render3DBAG(
  data
) {

  setStatus(
    "5/5 3D-model tekenen…"
  );


  if (model) {

    scene.remove(
      model
    );

    model.traverse(
      object => {

        if (
          object.geometry
        ) {

          object.geometry.dispose();
        }

        if (
          object.material
        ) {

          if (
            Array.isArray(
              object.material
            )
          ) {

            object.material.forEach(
              m => m.dispose()
            );

          } else {

            object.material.dispose();
          }
        }
      }
    );
  }


  model =
    new THREE.Group();


  /*
   * 3DBAG kan een enkele feature
   * teruggeven.
   */

  const feature =
    data.feature ||
    (
      Array.isArray(
        data.features
      )
        ? data.features[0]
        : null
    );


  if (!feature) {

    throw new Error(
      "Geen CityJSONFeature in 3DBAG-response."
    );
  }


  /*
   * CityJSONFeature heeft rechtstreeks:
   *
   * feature.CityObjects
   * feature.vertices
   * feature.transform
   */

  const cityObjects =
    feature.CityObjects ||
    {};


  const vertices =
    feature.vertices ||
    [];


  const transform =
    feature.transform ||
    null;


  if (
    !vertices.length
  ) {

    throw new Error(
      "3DBAG bevat geen vertices."
    );
  }


  /*
   * Transform toepassen.
   */

  function getVertex(
    index
  ) {

    const v =
      vertices[index];


    if (
      !v ||
      v.length < 3
    ) {

      return null;
    }


    let x =
      Number(v[0]);

    let y =
      Number(v[1]);

    let z =
      Number(v[2]);


    if (transform) {

      const scale =
        transform.scale ||
        [1, 1, 1];

      const translate =
        transform.translate ||
        [0, 0, 0];


      x =
        x * scale[0] +
        translate[0];

      y =
        y * scale[1] +
        translate[1];

      z =
        z * scale[2] +
        translate[2];
    }


    return {
      x,
      y,
      z
    };
  }


  /*
   * Zoek een lokale origin.
   *
   * De 3DBAG-coördinaten zijn RD/NAP.
   * Die zijn te groot om rechtstreeks
   * prettig in Three.js te gebruiken.
   */

  const first =
    getVertex(0);


  const origin =
    first || {
      x: 0,
      y: 0,
      z: 0
    };


  let triangleCount =
    0;


  const material =
    new THREE.MeshStandardMaterial({
      color: 0xd6d6d6,
      side: THREE.DoubleSide,
      roughness: 0.85
    });


  for (
    const [
      objectName,
      cityObject
    ]
    of Object.entries(
      cityObjects
    )
  ) {

    const geometries =
      cityObject.geometry ||
      [];


    for (
      const geometry
      of geometries
    ) {

      /*
       * boundaries:
       *
       * shell
       *   surface
       *     ring
       */

      const boundaries =
        geometry.boundaries ||
        [];


      for (
        const shell
        of boundaries
      ) {

        if (
          !Array.isArray(shell)
        ) {

          continue;
        }


        for (
          const surface
          of shell
        ) {

          if (
            !Array.isArray(surface)
          ) {

            continue;
          }


          /*
           * CityJSON:
           *
           * surface = [
           *   [0,1,2,3]
           * ]
           */

          const ring =
            Array.isArray(
              surface[0]
            )
              ? surface[0]
              : surface;


          if (
            !Array.isArray(ring) ||
            ring.length < 3
          ) {

            continue;
          }


          const points =
            ring
              .map(
                getVertex
              )
              .filter(Boolean)
              .map(
                v =>
                  new THREE.Vector3(
                    v.x -
                    origin.x,

                    v.z -
                    origin.z,

                    -(
                      v.y -
                      origin.y
                    )
                  )
              );


          if (
            points.length < 3
          ) {

            continue;
          }


          /*
           * Fan triangulation.
           */

          for (
            let i = 1;
            i < points.length - 1;
            i++
          ) {

            const geo =
              new THREE.BufferGeometry();


            const positions =
              new Float32Array([
                points[0].x,
                points[0].y,
                points[0].z,

                points[i].x,
                points[i].y,
                points[i].z,

                points[i + 1].x,
                points[i + 1].y,
                points[i + 1].z
              ]);


            geo.setAttribute(
              "position",
              new THREE.BufferAttribute(
                positions,
                3
              )
            );


            geo.computeVertexNormals();


            const mesh =
              new THREE.Mesh(
                geo,
                material.clone()
              );


            mesh.userData = {
              object:
                objectName
            };


            model.add(
              mesh
            );


            triangleCount++;
          }
        }
      }
    }
  }


  if (
    !model.children.length
  ) {

    throw new Error(
      "3DBAG bevat geen renderbare geometrie."
    );
  }


  scene.add(
    model
  );


  /*
   * Model centreren.
   */

  const box =
    new THREE.Box3()
      .setFromObject(
        model
      );


  const center =
    box.getCenter(
      new THREE.Vector3()
    );


  model.position.sub(
    center
  );


  const size =
    box.getSize(
      new THREE.Vector3()
    );


  const radius =
    Math.max(
      size.x,
      size.y,
      size.z,
      1
    );


  const distance =
    Math.max(
      radius * 2.5,
      20
    );


  camera.position.set(
    distance,
    distance * 0.75,
    distance
  );


  camera.near =
    0.01;

  camera.far =
    Math.max(
      1000,
      distance * 100
    );


  camera.updateProjectionMatrix();


  controls.target.set(
    0,
    0,
    0
  );

  controls.update();


  return triangleCount;
}


/* =========================================================
   ZOEKEN
========================================================= */

async function search() {

  const query =
    addressInput.value.trim();


  if (!query) {

    setStatus(
      "Vul eerst een adres in."
    );

    return;
  }


  goButton.disabled =
    true;

  errorBox.style.display =
    "none";

  info.style.display =
    "none";


  try {

    /*
     * ADRES
     */

    const address =
      await geocode(
        query
      );


    /*
     * BAG VERBLIJFSOBJECT
     */

    const vo =
      await findVerblijfsobject(
        address.lon,
        address.lat
      );


    /*
     * BAG PAND
     */

    const pand =
      await getPand(
        vo
      );


    /*
     * 3DBAG
     */

    const data =
      await get3DBAG(
        pand.identificatie
      );


    /*
     * RENDER
     */

    const triangleCount =
      render3DBAG(
        data
      );


    const vp =
      vo.properties ||
      {};

    const pp =
      pand.feature.properties ||
      {};


    info.innerHTML = `

      <b>
        ${escapeHtml(
          address.label
        )}
      </b>

      <div>
        BAG verblijfsobject:
        ${escapeHtml(
          vp.identificatie || ""
        )}
      </div>

      <div>
        BAG pand:
        ${escapeHtml(
          pand.identificatie
        )}
      </div>

      <div>
        Bouwjaar:
        ${escapeHtml(
          pp.bouwjaar ??
          "onbekend"
        )}
      </div>

      <div>
        3D-vlakken:
        ${triangleCount.toLocaleString(
          "nl-NL"
        )}
      </div>

    `;


    info.style.display =
      "block";


    setStatus(
      "Klaar — het 3D-gebouw is geladen."
    );


  } catch (error) {

    showError(
      error.message ||
      String(error)
    );

  } finally {

    goButton.disabled =
      false;
  }
}


/* =========================================================
   HTML ESCAPE
========================================================= */

function escapeHtml(
  value
) {

  return String(value)
    .replaceAll(
      "&",
      "&amp;"
    )
    .replaceAll(
      "<",
      "&lt;"
    )
    .replaceAll(
      ">",
      "&gt;"
    )
    .replaceAll(
      '"',
      "&quot;"
    )
    .replaceAll(
      "'",
      "&#039;"
    );
}


/* =========================================================
   KLIKKEN OP MODEL
========================================================= */

const raycaster =
new THREE.Raycaster();

const mouse =
new THREE.Vector2();


renderer.domElement.addEventListener(
  "click",
  event => {

    if (!model) {
      return;
    }


    const rect =
      renderer.domElement
        .getBoundingClientRect();


    mouse.x =
      (
        (
          event.clientX -
          rect.left
        ) /
        rect.width
      ) * 2 - 1;


    mouse.y =
      -(
        (
          event.clientY -
          rect.top
        ) /
        rect.height
      ) * 2 + 1;


    raycaster.setFromCamera(
      mouse,
      camera
    );


    const hits =
      raycaster.intersectObjects(
        model.children,
        true
      );


    if (!hits.length) {
      return;
    }


    const hit =
      hits[0];


    info.style.display =
      "block";


    info.innerHTML = `

      <b>
        3DBAG-oppervlak
      </b>

      <div>
        CityObject:
        ${escapeHtml(
          hit.object.userData.object ||
          "onbekend"
        )}
      </div>

    `;
  }
);


/* =========================================================
   EVENTS
========================================================= */

goButton.addEventListener(
  "click",
  search
);


addressInput.addEventListener(
  "keydown",
  event => {

    if (
      event.key === "Enter"
    ) {

      search();
    }
  }
);


/* =========================================================
   RESIZE
========================================================= */

window.addEventListener(
  "resize",
  () => {

    camera.aspect =
      viewer.clientWidth /
      viewer.clientHeight;


    camera.updateProjectionMatrix();


    renderer.setSize(
      viewer.clientWidth,
      viewer.clientHeight
    );
  }
);


/* =========================================================
   ANIMATIE
========================================================= */

function animate() {

  requestAnimationFrame(
    animate
  );

  controls.update();

  renderer.render(
    scene,
    camera
  );
}


animate();

</script>

</body>
</html>
