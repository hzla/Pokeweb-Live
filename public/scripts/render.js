/**
 * Convert mastersheet JSON (masterData + trainers + encounters) into HTML.
 *
 * Assumptions / conventions:
 * - masterData elements:
 *   - { tag: "h1"|"h3"|"h4"|"p", content, content_parts? }
 *   - { tag: "li", content, content_parts? }   // auto-grouped into <ul>...</ul>
 *   - { tag: "br" }
 *   - { tag: "trainer", id, class, notes? }
 *   - { tag: "encounter", id }
 * - trainers and encounters are arrays indexed by id (trainers[id], encounters[id]).
 *
 */

// POKEWEB MODE or Use LIVE CALC MODE if not serving dex and calc locally
// clicking on trainers will not update calc when testing locally (need same domain)
IMAGE_FOLDER = "images"
DEX_URL = "http://localhost:3001" 
CALC_URL = "http://localhost:3002?data=casc"

// LIVE CALC MODE
// IMAGE_FOLDER = "img"
// DEX_URL = "https://https://ddex-chi.vercel.app?game=cascadewhite"
// CALC_URL = "https://hzla.github.io/Dynamic-Calc-Decomps"

// LOCAL CALC MODE
// IMAGE_FOLDER = "img"
// DEX_URL = "http://localhost:3001" 
// CALC_URL = "http://localhost:3002?data=casc"

function renderMasterData(masterData, trainersById, encountersById) {
  let html = "";
  let ulOpen = false;
  let prevEmittedEmptyP = false;

  const closeUlIfOpen = () => {
    if (ulOpen) {
      html += `</ul>\n`;
      ulOpen = false;
    }
  };

  for (let i = 0; i < masterData.length; i++) {
    const el = masterData[i];
    const tag = el?.tag;

    const isEmptyP = tag === "p" && isEmptyParagraphEl(el);
    const ignoreEmptyPInsideList = ulOpen && isEmptyP;

    // list grouping:
    // Close the <ul> when we hit a non-li tag, *except* when it's an empty <p> we want to ignore
    if (tag !== "li" && !ignoreEmptyPInsideList) closeUlIfOpen();

    switch (tag) {
      case "br":
        prevEmittedEmptyP = false;
        html += `<br>\n`;
        break;

      case "h1":
      case "h2":
      case "h3":
      case "h4":
        prevEmittedEmptyP = false;
        html += `<${tag}>${renderInlineParts(el)}</${tag}>\n`;
        break;

      case "p": {
        if (isEmptyP) {
          // Ignore empty <p> while inside a list run
          if (ulOpen) break;

          // Collapse consecutive empty <p> into one
          if (prevEmittedEmptyP) break;

          prevEmittedEmptyP = true;
          html += `<p></p>\n`;
          break;
        }

        prevEmittedEmptyP = false;
        html += `<p>${renderInlineParts(el)}</p>\n`;
        break;
      }

      case "li":
        prevEmittedEmptyP = false;
        if (!ulOpen) {
          ulOpen = true;
          html += `<ul>\n`;
        }
        html += `<li>${renderInlineParts(el)}</li>\n`;
        break;

      case "trainer": {
        prevEmittedEmptyP = false;
        const trainer = getTrainer(trainersById, el.id);
        html += renderTrainerCard(el, trainer, i);
        break;
      }

      case "encounter": {
        prevEmittedEmptyP = false;
        const enc = getEncounter(encountersById, el.id);
        html += renderEncounterCard(el, enc);
        break;
      }

      case "gifts": {
        prevEmittedEmptyP = false;
        html += renderGiftsBlock(el);
        break;
      }

      case "items": {
        prevEmittedEmptyP = false;
        html += renderItemsBlock(el);
        break;
      }

      case "notif": {
        prevEmittedEmptyP = false;
        html += renderNotificationBlock(el);
        break;
      }

      default: {
        prevEmittedEmptyP = false;
        // Custom Tags
        break;
      }
    }
  }

  closeUlIfOpen();
  return html;
}

/* ----------------------------- inline rendering ---------------------------- */

function renderInlineParts(el) {
  const parts = Array.isArray(el.content_parts) ? el.content_parts : null;

  if (!parts) return escapeHtml(el.content ?? "");

  return parts
    .map((p) => {
      if (p?.type === "text") return escapeHtml(p.text ?? "");
      if (p?.type === "link") {
        const href = sanitizeUrl(p.href ?? "#");
        const text = escapeHtml(p.text ?? href);
        return `<a href="${href}" target="_blank" rel="noopener noreferrer">${text}</a>`;
      }
      // fallback
      return escapeHtml(p?.text ?? "");
    })
    .join("");
}

/* ----------------------------- trainer rendering --------------------------- */

function renderTrainerCard(masterEl, trainer, elementIndex) {

  const msClass = masterEl.class ? escapeAttr(masterEl.class) : "";
  const notes = Array.isArray(masterEl.notes) ? masterEl.notes : [];

  const dataIndex = masterEl.id ?? "";
  const dataElement = ""; 

  const trainerDisplayName = buildTrainerDisplayName(trainer);
  const trainerSpriteSrc = buildTrainerSpriteSrc(trainer);

  const battleType = trainer.type
  const shouldShowBattleType = (battleType == "Doubles" || battleType == "Triples")

  let html = "";
  html += `<div class="expanded-field filterable ms-trainer ${msClass} " data-index="${escapeAttr(
    String(dataIndex)
  )}" data-element="${escapeAttr(String(dataElement))}" >\n`;
  html += `  <div class="expanded-field-main">\n`;
  html += `    <div class="trainer-name">`;
  html += `<img src="${escapeAttr(trainerSpriteSrc)}" class="" loading="lazy" data-="" /> `;
  html += `${trainerDisplayName}\n`;
  html += `      <div class="tr-notes">\n`;

  for (const n of notes) html += `        ${escapeHtml(String(n))}\n`;

  if (shouldShowBattleType) {
    html += `<br>(${battleType})\n`
  }

 

  html += `      </div>\n`;
  html += `    </div>\n`;
  html += `  </div>\n\n`;

  html += `  <div class="expanded-card-content expanded-docs">\n`;
  html += renderTrainerDocs(trainer);
  html += `  </div>\n`;
  html += `</div>\n`;

  return html;
}

function renderTrainerDocs(trainer) {
  if (!trainer) return ``;

  const count = Number(trainer.count ?? 0);
  if (!Number.isFinite(count) || count <= 0) return ``;

  // Wrap text in a span that forces bold + italic if highlighted
  function maybeEmphasize(rawName, displayText) {
    const key = cleanString(String(rawName ?? ""));
    const safeText = escapeHtml(String(displayText ?? ""));

    if (!key) return safeText;

    const h = (typeof highlights === "object" && highlights) ? highlights : null;
    const isHighlighted =
      (h?.changed && h.changed[key] === 1) ||
      (h?.new && h.new[key] === 1);

    if (!isHighlighted) return safeText;

    return `<span style="font-style: italic;color: #f1fa8c";>${safeText}</span>`;
  }

  let html = "";

  for (let slot = 0; slot < count; slot++) {
    const speciesRaw = trainer[`species_id_${slot}`] ?? "";
    const rawSpeciesId = trainer[`raw_species_id_${slot}`];
    const level = trainer[`level_${slot}`] ?? "";
    const item = trainer[`item_id_${slot}`] ?? "";
    const nature = trainer[`nature_${slot}`] ?? "";
    const abilityName = trainer[`ability_name_${slot}`] ?? "";

    const displaySpecies = prettifyEnumName(speciesRaw);
    const spriteSrc = buildPokeSpriteSrc(displaySpecies);

    html += `    <div class="trainer-doc-item">\n`;
    html += `      <img src="${escapeAttr(spriteSrc)}" class="doc-sprite" loading="lazy" data-species-id="${escapeAttr(
      String(rawSpeciesId ?? "")
    )}" />\n`;

    html += `      <div class="trpok-item-info doc-species" data-species-id="${escapeAttr(
      String(rawSpeciesId ?? "")
    )}">Lv ${escapeHtml(String(level))} ${escapeHtml(displaySpecies)}</div>\n`;

    html += `      <div class="trpok-item-info doc-held-item">${maybeEmphasize(
      item,
      String(item ?? "")
    )}</div>\n`;

    html += `      <div class="trpok-item-info">\n        ${escapeHtml(String(nature))}\n      </div>\n`;

    html += `      <div class="trpok-item-info doc-ab">\n        ${maybeEmphasize(
      abilityName,
      String(abilityName ?? "")
    )}\n      </div>\n`;

    html += `      <br>\n\n`;

    for (let m = 1; m <= 4; m++) {
      const move = trainer[`move_${m}_${slot}`] ?? "";
      const moveDisplay = prettifyMoveName(move);

      html += `      <div class="trpok-item-info doc-move" data-id="0">${maybeEmphasize(
        move,
        moveDisplay
      )}</div>\n\n`;
    }

    html += `    </div>\n\n`;
  }

  return html;
}




function buildTrainerDisplayName(trainer) {
  // Sample output shows: "PkMn Trainer Bianca"
  // Your trainer object has "class": "Team Plasma" etc.
  const cls = trainer?.class ? escapeHtml(String(trainer.class)) : "Trainer";
  // If you have a separate name field, use it. Otherwise, just class.
  const name = trainer?.name ? escapeHtml(String(trainer.name)) : cls;
  return `${cls} ${name}`;
}

function buildTrainerSpriteSrc(trainer) {
  // In your trainer objects you have: tr_sprite: "trainer_sprites/teamplasma.png"
  // Your HTML sample used "/${IMAGE_FOLDER}/trainer_sprites/bianca.png"
  const raw = trainer?.tr_sprite ?? "";
  if (!raw) return `./${IMAGE_FOLDER}/trainer_sprites/unknown.png`;

  // if already looks like a path fragment
  if (raw.startsWith("/${IMAGE_FOLDER}/")) return raw;
  if (raw.startsWith("trainer_sprites/")) return `./${IMAGE_FOLDER}/${raw}`;
  if (raw.startsWith("/")) return raw;

  // fallback
  return `./${IMAGE_FOLDER}/${raw}`;
}


/* ---------------------------- empty line rendering -------------------------- */

function getInlinePlainText(el) {
  const parts = Array.isArray(el?.content_parts) ? el.content_parts : null;

  if (!parts) return String(el?.content ?? "");

  return parts
    .map((p) => {
      if (!p) return "";
      if (p.type === "text") return String(p.text ?? "");
      if (p.type === "link") return String(p.text ?? p.href ?? "");
      return String(p.text ?? "");
    })
    .join("");
}

function isEmptyParagraphEl(el) {
  // "Empty" = only whitespace or empty string
  return getInlinePlainText(el).trim().length === 0;
}


/* ---------------------------- encounter rendering -------------------------- */

function renderEncounterCard(masterEl, encounter) {
  if (!encounter) return ``;

  const dataIndex = masterEl.id ?? "";

  // Your sample has an extra hidden h3 preceding encounter card
  let html = "";
  html += `<h3 style="display: none;">${escapeHtml(encounter.name ?? "")}</h3>\n`;
  html += `<div class="expanded-field filterable doc-enc" data-index="${escapeAttr(
    String(dataIndex)
  )}">\n`;
  html += `  <div class="expanded-field-main">\n`;
  html += `    <div class="encounter-locations">\n`;
  html += `      ${escapeHtml(encounter.name ?? "")}\n`;
  html += `    </div>\n\n`;

  html += `    <div class="encounter-wilds" >\n`;
  const wilds = Array.isArray(encounter.wilds) ? encounter.wilds : [];
  for (const w of wilds) {
    const speciesName = String(w);
    const spriteSrc = buildPokeSpriteSrc(speciesName);

    html += `      <div class="wild" data-species-name="${escapeAttr(speciesName)}">\n`;
    html += `        <img src="${escapeAttr(
      spriteSrc
    )}" class="" loading="lazy" data-="" />\n`;
    html += `      </div>\n`;
  }
  html += `    </div>\n`;
  html += `  </div>\n`;
  html += `</div>\n`;

  return html;
}

/* ------------------------------- data access ------------------------------ */

function getTrainer(trainersById, id) {
  if (!trainersById) return null;

  // if it's an array indexed by id
  if (Array.isArray(trainersById)) return trainersById[id] ?? null;

  // if it's a map/dict keyed by id
  return trainersById[String(id)] ?? trainersById[id] ?? null;
}

function getEncounter(encountersById, id) {
  if (!encountersById) return null;

  if (Array.isArray(encountersById)) return encountersById[id] ?? null;
  return encountersById[String(id)] ?? encountersById[id] ?? null;
}

/* --------------------------------- sprites -------------------------------- */

function buildPokeSpriteSrc(speciesName) {
  // sample uses: /images/pokesprite/natu.png
  // Make sure your sprite naming matches this:
  // - lowercase
  // - spaces/hyphens normalized if needed
  const file = normalizeSpriteFileName(speciesName);
  return `./${IMAGE_FOLDER}/pokesprite/${file}.png`;
}

function normalizeSpriteFileName(name) {
  // "Mr. Mime" -> "mr_mime" (adjust if your sprite pack differs)
  return String(name)
    .trim()
    .toLowerCase()
    .replace(/\./g, "")
    .replace(/['’]/g, "")
    .replace(/[♀]/g, "f")
    .replace(/[♂]/g, "m")
}

/* -------------------------- gifts / items / notif -------------------------- */

function normalizeViaCleanString(name) {
  const raw = String(name ?? "").trim();
  if (!raw) return "";
  // Prefer your project’s cleanString() if it exists (you said it does)
  if (typeof cleanString === "function") return cleanString(raw);
  // Fallback to existing sprite normalization
  return normalizeSpriteFileName(raw);
}

function buildGiftPokeSpriteSrc(pokemonName) {
  const file = normalizeViaCleanString(pokemonName);
  return `./${IMAGE_FOLDER}/pokesprite/${file}.png`;
}

function buildItemSpriteSrc(itemName) {
  const file = normalizeViaCleanString(itemName);
  return `./${IMAGE_FOLDER}/item_sprites/${file}.png`;
}

// allow only <br> line breaks from user-provided HTML-ish text
function allowOnlyBr(htmlish) {
  const escaped = escapeHtml(String(htmlish ?? ""));
  return escaped
    .replace(/&lt;br\s*\/?&gt;/gi, "<br>");
}

/* --------------------------------- GIFTS --------------------------------- */

function renderGiftsBlock(el) {
  const title = escapeHtml(el.giftsTitle ?? "");
  const desc = escapeHtml(el.giftsDescription ?? "");

  const mons = Array.isArray(el.giftPokemonList) ? el.giftPokemonList : [];
  const monDescs = Array.isArray(el.giftPokemonDescriptions) ? el.giftPokemonDescriptions : [];

  // table-like layout using divs (no strict styling assumptions)
  let html = "";
  html += `<div class="flex-break"></div>\n`
  html += `<div class="ms-block ms-gifts">\n`;
  html += `  <div class="ms-row">\n`;
  html += `    <div class="ms-left">\n`;
  html += `      <div class="ms-left-title">${title}</div>\n`;
  if (desc) html += `      <div class="ms-left-desc">${desc}</div>\n`;
  html += `    </div>\n`;

  html += `    <div class="ms-cells">\n`;
  for (let i = 0; i < mons.length; i++) {
    const mon = String(mons[i] ?? "");
    const monDesc = String(monDescs[i] ?? "");
    const sprite = buildGiftPokeSpriteSrc(mon);

    html += `      <div class="ms-cell ms-gift-cell" data-species-name="${escapeAttr(mon)}">\n`;
    html += `        <div class="ms-cell-top">\n`;
    html += `          <img src="${escapeAttr(sprite)}" loading="lazy" alt="${escapeAttr(mon)}" />\n`;
    html += `        </div>\n`;

    if (monDesc) {
      html += `        <div class="ms-cell-bottom">\n`;
      html += `          <div class="ms-gift-desc">${escapeHtml(monDesc)}</div>\n`;
      html += `        </div>\n`;
    } else {
      // truly empty element → :empty works, no whitespace nodes
      html += `        <div class="ms-cell-bottom"></div>\n`;
    }

    html += `      </div>\n`;
  }
  html += `    </div>\n`;

  html += `  </div>\n`;
  html += `</div>\n`;
  html += `<div class="flex-break"></div>\n`

  return html;
}

/* --------------------------------- ITEMS --------------------------------- */

function cleanString(str) {return str.replace(/[^a-zA-Z0-9]/g, '').toLowerCase()};

function renderItemsBlock(el) {
  const title = escapeHtml(el.itemsTitle ?? "");
  const desc = escapeHtml(el.itemsDescription ?? "");

  const items = Array.isArray(el.itemList) ? el.itemList : [];
  const itemDescs = Array.isArray(el.itemDescriptions) ? el.itemDescriptions : [];

  let html = "";
  html += `<div class="ms-block ms-items">\n`;
  html += `  <div class="ms-row">\n`;
  html += `    <div class="ms-left">\n`;
  html += `      <div class="ms-left-title">${title}</div>\n`;
  if (desc) html += `      <div class="ms-left-desc">${desc}</div>\n`;
  html += `    </div>\n`;

  html += `    <div class="ms-item-rows">\n`;
  for (let i = 0; i < items.length; i++) {
    const item = String(items[i] ?? "").replace("é", "e");
    const itemDesc = String(itemDescs[i] ?? "");
    const sprite = buildItemSpriteSrc(item);

    html += `      <div class="ms-item-row" data-item-name="${escapeAttr(item)}">\n`;
    html += `        <div class="ms-item-icon">\n`;
    html += `          <img src="${escapeAttr(sprite)}" loading="lazy" alt="${escapeAttr(item)}" onerror="this.onerror=null; this.src='${IMAGE_FOLDER}/default.png'"/>\n`;
    html += `        </div>\n`;
    html += `        <div class="ms-item-text">\n`;
    // If you want the item name visible separate from the description, uncomment:
    // html += `          <div class="ms-item-name">${escapeHtml(item)}</div>\n`;
    html += `          <div class="ms-item-desc">${escapeHtml(itemDesc || item)}</div>\n`;
    html += `        </div>\n`;
    html += `      </div>\n`;
  }
  html += `    </div>\n`;

  html += `  </div>\n`;
  html += `</div>\n`;

  return html;
}

/* --------------------------------- NOTIF --------------------------------- */

function renderNotificationBlock(el) {
  const title = escapeHtml(el.notificationTitle ?? "NOTE");
  // your sample uses "text" and includes <br>
  const body = allowOnlyBr(el.text ?? "");
  const color = el.fontColor ?? ""

  let html = "";
  html += `<div class="flex-break"></div>\n`
  html += `<div class="ms-block ms-notif">\n`;
  html += `  <div class="ms-row">\n`;
  html += `    <div class="ms-left" style="background: ${color}">\n`;
  html += `      <div class="ms-left-title">${title}</div>\n`;
  html += `    </div>\n`;
  html += `    <div class="ms-notif-body">${body.replaceAll(",", ", ")}</div>\n`;
  html += `  </div>\n`;
  html += `</div>\n`;
  html += `<div class="flex-break"></div>\n`

  return html;
}


/* ------------------------------ text utilities ---------------------------- */

function prettifyEnumName(s) {
  // "CHIMECHO" -> "Chimecho", "PERISH SONG" -> "Perish Song"
  const str = String(s ?? "").trim();
  if (!str) return "";
  return str
    .toLowerCase()
    .split(/[\s_]+/g)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

function prettifyMoveName(s) {
  // If your move strings are already nice, you can just return s.
  return prettifyEnumName(s);
}

/* ------------------------------ Dex ---------------------------- */

function loadDex(url) {
  // Create iframe element

  if ($('iframe.dex-window').length > 0) {
    $('iframe').show()
    $('.iframe-close-btn').show()
    return;
  }

  const iframe = document.createElement('iframe');

  // Set iframe properties
  iframe.src = `${DEX_URL}/${url}`;
  iframe.classList.add("dex-window");
  iframe.style.position = 'fixed';
  iframe.style.top = '44px';
  iframe.style.left = '0%';
  iframe.style.width = '18vw';
  iframe.style.height = 'calc(100vh - 44px)';
  iframe.style.border = '2px solid #333';
  iframe.style.zIndex = '999999';
  iframe.style.boxShadow = '0 4px 20px rgba(0,0,0,0.3)';
  iframe.style.display = 'none';

  // Add elements to page
  document.body.appendChild(iframe);
}

function extractPokemonName(str) {
  const match = str.match(/^(?:Lv|Lvl)\s*\d+\s+(.*)$/i);
  return match ? match[1] : null;
}

function loadDexPage(collection, speciesName) {
  $('iframe.dex-window').remove()
  $('#toc').hide()
  $('.filter-title').removeClass('active')
  $('.dex-tab').addClass('active')
  loadDex(`${collection}/${speciesName}`)
  $('iframe.dex-window').show()
}

function constructToc() {
  let tocCounter = 0;
  const $toc = $('#toc');
  $toc.empty(); // important if you ever reconstruct

  $('h1, h2').each(function() {
    if (tocCounter === 0) {
      tocCounter += 1;
      return;
    }

    const text = $(this).text().split(" (")[0];

    const dataLink = text.trim().toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .trim();

    $(this).attr('data-link', dataLink);

    let tocHTML = "";
    if ($(this).is('h1')) {
      tocHTML = `<div class="toc-header" data-link="${dataLink}">${text}</div>`;
    } else {
      tocHTML = `<div class="toc-item" data-link="${dataLink}">${text}</div>`;
    }

    $toc.append(tocHTML);
  });

  // init deterministic stacking AFTER the DOM nodes exist
  const tocEl = document.getElementById("toc");
  tocStacking = setupStackingToc(tocEl);
}

// --- deterministic stacking controller (stable thresholds) ---
let tocStacking = null;

function setupStackingToc(tocEl) {
  const toc = tocEl;
  const headers = Array.from(toc.querySelectorAll(".toc-header"));

  let heights = [];
  let thresholds = [];

  function recompute() {
    // measure heights (sticky doesn't change flow height)
    heights = headers.map(h => h.offsetHeight);

    // thresholds[i] = offsetTop(header[i]) - sum(heights before i)
    thresholds = [];
    let pileBefore = 0;
    for (let i = 0; i < headers.length; i++) {
      thresholds[i] = headers[i].offsetTop - pileBefore;
      pileBefore += heights[i];
    }

    layout();
  }

  function layout() {
    const s = toc.scrollTop;
    let stack = 0;

    for (let i = 0; i < headers.length; i++) {
      if (s >= thresholds[i]) {
        headers[i].style.top = stack + "px";
        stack += heights[i];
      } else {
        headers[i].style.top = "0px";
      }
    }
  }

  function scrollToHeader(headerEl, { smooth = true } = {}) {
    const i = headers.indexOf(headerEl);
    if (i === -1) return;

    // Always the same target for the same header:
    const target = thresholds[i];

    toc.scrollTo({
      top: Math.max(0, target),
      behavior: smooth ? "smooth" : "auto",
    });

    // keep stacking in sync during smooth scroll
    requestAnimationFrame(layout);
  }

  // wire scroll/resize
  toc.addEventListener("scroll", layout, { passive: true });
  window.addEventListener("resize", recompute);

  // initial compute
  recompute();

  return { recompute, layout, scrollToHeader, headers };
}

function scrollTocToHeader(headerEl) {
  if (!tocStacking) return;
  tocStacking.scrollToHeader(headerEl, { smooth: true });
}

/* ------------------------------ safety helpers ---------------------------- */

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function escapeAttr(s) {
  // Keep it simple; attributes should be escaped too
  return escapeHtml(s).replaceAll("`", "&#096;");
}

function sanitizeUrl(url) {
  const u = String(url ?? "").trim();
  // allow http(s) only; otherwise, neutralize
  if (/^https?:\/\//i.test(u)) return u;
  return "#";
}

$(document).ready(function() {
    document.querySelector("#mastersheet").innerHTML = renderMasterData(masterData, trainersById, encountersById);
    constructToc()

    loadDex("?game=cascadewhite")

    $('.doc-sprite, .doc-species').click(function() {
      let speciesName = cleanString(extractPokemonName($(this).parent().find('.doc-species').text()))
      loadDexPage("pokemon", speciesName)
    })

    $('.doc-move').click(function() {
      let moveName = cleanString($(this).text())
      loadDexPage("moves", moveName)
    })

    $('.doc-ab').click(function() {
      let abName = cleanString($(this).text())
      loadDexPage("abilities", abName)
    })

    $('.doc-held-item').click(function() {
      let itemName = cleanString($(this).text())
      loadDexPage("items", itemName)
    })

    $('.doc-enc').click(function() {
      let encName = cleanString($(this).find('.encounter-locations').text())
      loadDexPage("encounters", encName)
    })

    $('.wild').click(function() {
      let speciesName = cleanString($(this).attr('data-species-name'))
      loadDexPage("pokemon", speciesName)
    })

    $('.dex-tab').click(function() {
      $('iframe.dex-window').show()
      $('#toc').hide()
      $('.filter-title').removeClass('active')
      $(this).addClass('active')
    })

    $('.calc-tab').click(function() {
      $('.calc-drawer').show()
      loadCalc(CALC_URL)
      $('.filter-title').removeClass('active')
      $(this).addClass('active')
    })

    $('.toc-tab').click(function() {
      $('iframe.dex-window, .calc-drawer').hide()
      $('#toc').show()
      $('.filter-title').removeClass('active')
      $(this).addClass('active')
    })

    $('#toc div').on('click', function(event) {
        $('iframe.dex-window, .calc-drawer').hide()
        event.preventDefault(); // Prevent default action, like link navigation

        // Get the value of the data-link attribute from the clicked element
        var targetDataLink = $(this).attr('data-link');

        // Find the target element with the matching data-link attribute
        

        var targetElement = $('#mastersheet').find('[data-link="' + targetDataLink + '"]').first();

        if (targetElement.length) {
            // Scroll to the target element
            $('#content-container').scrollTop(0)
            $('#content-container').scrollTop( targetElement.offset().top)

            scrollTocToHeader($(this)[0])
        } else {
            console.log('Target element with data-link="' + targetDataLink + '" not found.');
        }
    });

    const toc = document.getElementById('toc');
    window.addEventListener("resize", layoutPile);
})

/* ------------------------------ Tab Communications ---------------------------- */

// --- Calc loader w/ readiness gate ---
let calcReady = false;
let calcReadyPromise = null;

function openExistingDrawer() {
  const existing = document.querySelector('.calc-drawer');
  if (!existing) return null;

  existing.style.display = '';
  $('.iframe-close-btn').show();
  requestAnimationFrame(() => existing.classList.add('is-open'));
  return existing;
}

function loadCalc(url) {
  // If already created, just open + return the existing readiness promise
  const existing = openExistingDrawer();
  if (existing) {
    // If it's already ready, resolve immediately
    if (calcReady) return Promise.resolve();
    // Otherwise return whatever promise we created when we first built it
    if (calcReadyPromise) return calcReadyPromise;

    // Fallback: if something created the drawer without our promise, wire it now
    const iframe = existing.querySelector('iframe.calc-window');
    calcReadyPromise = new Promise((resolve) => {
      if (!iframe) return resolve(); // nothing to wait for
      if (iframe.contentWindow && iframe.contentDocument?.readyState === "complete") {
        calcReady = true;
        return resolve();
      }
      iframe.addEventListener('load', () => {
        calcReady = true;
        resolve();
      }, { once: true });

      // Safety timeout so you don't get stuck forever
      setTimeout(() => resolve(), 8000);
    });
    return calcReadyPromise;
  }

  // Create drawer
  const drawer = document.createElement('div');
  drawer.className = 'calc-drawer';

  Object.assign(drawer.style, {
    position: 'fixed',
    top: '0',
    right: '0',
    width: '82vw',
    height: '100vh',
    zIndex: '999999',
    overflow: 'hidden',
    border: '2px solid #333',
    boxShadow: '0 4px 20px rgba(0,0,0,0.3)',
    background: 'transparent',
    transform: 'translateX(100%)',
    transition: 'transform 0.5s ease-out',
    willChange: 'transform'
  });

  const iframe = document.createElement('iframe');
  iframe.className = 'calc-window';

  // Start loading ASAP
  iframe.src = CALC_URL; // or `${CALC_URL}/${url}` if needed
  iframe.loading = 'eager';

  Object.assign(iframe.style, {
    width: '100%',
    height: '100%',
    border: '0',
    display: 'block',
    background: 'transparent'
  });

  drawer.appendChild(iframe);
  document.body.appendChild(drawer);

  // Trigger slide-in next frame
  requestAnimationFrame(() => {
    drawer.style.transform = 'translateX(0)';
    drawer.classList.add('is-open');
  });

  // Create a one-time readiness promise for THIS iframe
  calcReady = false;
  calcReadyPromise = new Promise((resolve) => {
    iframe.addEventListener('load', () => {
      calcReady = true;
      resolve();
    }, { once: true });

    // Safety timeout so click doesn't get stuck if load never fires
    setTimeout(() => resolve(), 8000);
  });

  return calcReadyPromise;
}


// --- BroadcastChannel plumbing (unchanged) ---
const channel = new BroadcastChannel("my_app_channel");
const TAB_ID = crypto.randomUUID?.() ?? String(Date.now()) + Math.random();

function onMessage(handler) {
  channel.addEventListener("message", (e) => {
    const msg = e.data;
    if (!msg || msg.sender === TAB_ID) return;
    handler(msg);
  });
}

function send(type, payload) {
  channel.postMessage({
    sender: TAB_ID,
    type,
    payload,
    ts: Date.now(),
  });
}

function close() {
  channel.close();
}


// --- Click: ensure calc is loaded BEFORE sending setId ---
$(document).on("click", ".trainer-name", async function () {
  const setId = $(this).closest(".ms-trainer").attr("data-index");
  if (setId == null) return;

  // Open/create + wait until iframe load fired
  await loadCalc(CALC_URL);

  // Now it's safe to send (calc is loaded)
  send("SET_ID", { setId: String(setId) });
  $('.filter-title').removeClass('active')
  $('.calc-tab').addClass('active')
});





