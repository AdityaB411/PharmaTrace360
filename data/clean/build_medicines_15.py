"""
build_medicines_15.py  v4
Reads two Kaggle raw CSVs (read-only) and writes data/clean/medicines_15.csv.

REPRODUCIBILITY: All hand-supplied values are in the OVERRIDES section below.
Changing anything in OVERRIDES will change the output CSV. Every value there
is also documented in docs/data_overrides.md with its reason.
"""

import csv, json, re, os, sys, io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

PROJECT_ROOT = Path(__file__).resolve().parents[2]
AZ  = PROJECT_ROOT / 'data' / 'raw' / 'Extensive_A_Z_medicines_dataset_of_India.csv'
MD  = PROJECT_ROOT / 'data' / 'raw' / 'medicine_data.csv'
OUT = PROJECT_ROOT / 'data' / 'clean' / 'medicines_15.csv'
os.makedirs(OUT.parent, exist_ok=True)

# ══════════════════════════════════════════════════════════════════════════════
# OVERRIDES — all hand-supplied values that are NOT taken directly from the
#             Kaggle CSV files.  Documented in docs/data_overrides.md.
# ══════════════════════════════════════════════════════════════════════════════

# 1. Pantoprazole brand choice
#    The scoring function would pick a Sun/Aristo brand first, but 'Lupipan'
#    (Lupin Ltd) is a well-known generic that makes the demo more realistic.
#    Implemented by placing 'lupin' first in the Pantoprazole mfr preference
#    list below — no post-hoc patch needed; the scorer naturally picks it.
#    Reason: diversity of manufacturers in demo data (Lupin not otherwise present
#    in the top 15 except Levocetirizine/Elate).
PANTOPRAZOLE_MFR_PREFS = ['lupin', 'sun pharma', 'sun pharmaceutical', 'aristo',
                           'alkem', 'cipla']

# 2. Hand-supplied drug-interaction lists (fallback, used only when
#    medicine_data.csv has no single-ingredient row for these salts).
#    Source: well-known public drug-drug interactions (textbook / BNF level).
FALLBACK_INTERACTIONS = {
    # Amoxycillin: anticoagulant potentiation, folate antagonist interaction,
    # uricosuric displacement, gout-drug interaction — standard references.
    'amoxycillin':  ['Warfarin', 'Methotrexate', 'Allopurinol', 'Probenecid'],
    'amoxicillin':  ['Warfarin', 'Methotrexate', 'Allopurinol', 'Probenecid'],

    # Atorvastatin: CYP3A4 inhibitors raise statin plasma levels (myopathy risk);
    # Gemfibrozil raises statin AUC; Rifampicin is a CYP3A4 inducer (lowers
    # statin); Digoxin levels increased by atorvastatin.
    'atorvastatin': ['Clarithromycin', 'Erythromycin', 'Gemfibrozil',
                     'Rifampicin', 'Digoxin'],

    # Amlodipine: Simvastatin dose-cap interaction (FDA warning); Cyclosporine
    # raises amlodipine AUC; Rifampicin induces CYP3A4; Tacrolimus interaction.
    'amlodipine':   ['Simvastatin', 'Cyclosporine', 'Rifampicin', 'Tacrolimus'],
}
FALLBACK_SOURCE = 'known drug interaction data, demo only'

# 3. Generic storage note applied to all 15 medicines
#    Neither Kaggle file contains storage conditions.  This text is a
#    standard cool-dry-place instruction suitable for most solid-dose medicines.
STORAGE = 'Store below 25 C, in a cool dry place, away from light'

# ══════════════════════════════════════════════════════════════════════════════
# END OVERRIDES
# ══════════════════════════════════════════════════════════════════════════════

UNICODE_HYPHENS = re.compile(r'[\u2010\u2011\u2012\u2013\u2014\u2015\u2212]')

def norm(s):
    return UNICODE_HYPHENS.sub('-', s).strip()

def parse_strength(comp_str):
    m = re.match(r'^(.+?)\s*\(([^)]+)\)\s*$', comp_str.strip())
    if m:
        return norm(m.group(1)), norm(m.group(2))
    return norm(comp_str), ''

def extract_salt_key(comp_str):
    m = re.match(r'^(.+?)\s*\(', comp_str.strip())
    if m:
        return m.group(1).strip().lower()
    return comp_str.strip().lower()

def flatten_uses(row):
    uses = [norm(row.get(f'use{i}', '')) for i in range(5)]
    return '; '.join(u for u in uses if u)

def normalize_list(s, sep=','):
    parts = [norm(p) for p in s.split(sep) if p.strip()]
    return '; '.join(parts)

def extract_form(pack_label):
    pl = pack_label.lower()
    if 'tablet'     in pl: return 'Tablet'
    if 'capsule'    in pl: return 'Capsule'
    if 'syrup'      in pl: return 'Syrup'
    if 'suspension' in pl: return 'Suspension'
    if 'drops'      in pl: return 'Drops'
    if 'injection'  in pl: return 'Injection'
    if 'infusion'   in pl: return 'Infusion'
    if 'cream'      in pl: return 'Cream'
    if 'gel'        in pl: return 'Gel'
    return pack_label.strip().title()

def form_priority(pack_label):
    f = extract_form(pack_label).lower()
    p = {'tablet':0,'capsule':1,'syrup':2,'suspension':3}
    return p.get(f, 9)

def strength_mg(comp_str):
    """Extract numeric mg value for sorting (higher = better for preference)."""
    m = re.search(r'(\d+(?:\.\d+)?)\s*mg', comp_str, re.I)
    return float(m.group(1)) if m else 0.0

# ── Target list with per-salt manufacturer priorities ─────────────────
# (salt_name_exact, [mfr_substrings_in_priority_order], min_strength_hint)
# NOTE: Pantoprazole uses PANTOPRAZOLE_MFR_PREFS from OVERRIDES above.
TARGETS = [
    ('Paracetamol',    ['cipla', 'alkem', 'sun pharma', 'sun pharmaceutical', 'mankind'],        500),
    ('Amoxycillin',    ['alkem', 'cipla', 'lupin', 'alembic', 'torrent', 'sun pharma'],          500),
    ('Azithromycin',   ['alembic', 'cipla', 'lupin', 'zydus', 'sun pharma'],                     500),
    ('Metformin',      ['sun pharma', 'sun pharmaceutical', 'alkem', 'lupin', 'cipla'],           500),
    ('Atorvastatin',   ['zydus', 'cadila', 'lupin', 'torrent', 'cipla', 'alkem'],                 10),
    ('Omeprazole',     ['alkem', 'torrent', 'cipla', 'mankind', 'sun pharma'],                    20),
    ('Cetirizine',     ['cipla', 'mankind', 'alkem', 'lupin'],                                    10),
    ('Ibuprofen',      ['abbott', 'micro labs', 'ipca', 'glenmark', 'cipla'],                    400),
    ('Pantoprazole',   PANTOPRAZOLE_MFR_PREFS,                                                    40),  # OVERRIDE
    ('Amlodipine',     ['mankind', 'intas', 'torrent', 'cipla', 'alkem'],                          5),
    ('Metronidazole',  ['ipca', 'alkem', 'lupin', 'cipla', 'aristo'],                            400),
    ('Doxycycline',    ['lupin', 'alkem', 'zydus', 'cipla'],                                     100),
    ('Ciprofloxacin',  ['cipla', 'alkem', 'lupin', 'torrent'],                                   500),
    ('Aspirin',        ['usv', 'micro labs', 'cipla'],                                            75),
    ('Levocetirizine', ['lupin', 'torrent', 'mankind', 'cipla', 'alkem'],                          5),
]

# ── STEP 1: load A-Z ──────────────────────────────────────────────────
print("Loading A-Z file...")
az_rows = []
with open(AZ, encoding='utf-8', errors='replace') as f:
    for row in csv.DictReader(f):
        if row['Is_discontinued'].strip().lower() == 'true': continue
        if not row['use0'].strip():                           continue
        if not row['Consolidated_Side_Effects'].strip():      continue
        if row['short_composition2'].strip():                 continue  # single-ingredient only
        az_rows.append(row)
print(f"  Eligible AZ rows: {len(az_rows)}")

# ── STEP 2: pick best row per salt ────────────────────────────────────
chosen = {}

for (salt_name, mfr_prefs, strength_hint) in TARGETS:
    salt_lower = salt_name.lower()
    alts = [salt_lower]
    if salt_lower == 'amoxycillin': alts.append('amoxicillin')

    candidates = [r for r in az_rows
                  if extract_salt_key(r['short_composition1']) in alts]

    if not candidates:
        print(f"  WARNING: '{salt_name}' -- no exact match")
        chosen[salt_lower] = None
        continue

    def score(row):
        m = row['manufacturer_name'].lower()
        mfr_s = next((i for i, p in enumerate(mfr_prefs) if p in m), len(mfr_prefs))
        form_s = form_priority(row['pack_size_label'])
        mg = strength_mg(row['short_composition1'])
        str_dist = abs(mg - strength_hint)
        return (mfr_s, form_s, str_dist)

    candidates.sort(key=score)
    chosen[salt_lower] = candidates[0]
    best = candidates[0]
    print(f"  AZ [{salt_name}]: {best['name']} | {best['manufacturer_name']} | "
          f"{best['short_composition1']} | {extract_form(best['pack_size_label'])}")

# ── STEP 3: load medicine_data single-ingredient rows ─────────────────
print("\nLoading medicine_data file...")
md_index = {}
with open(MD, encoding='utf-8', errors='replace') as f:
    for row in csv.DictReader(f):
        sc = row['salt_composition'].strip()
        if '+' in sc: continue
        di_raw = row['drug_interactions'].strip()
        if not di_raw or di_raw in ('{}', '[]', '{"drug":[],"brand":[],"effect":[]}'):
            continue
        key = extract_salt_key(sc)
        md_index.setdefault(key, []).append(row)

print(f"  Single-ingredient rows with interactions: {sum(len(v) for v in md_index.values())}")

def get_interactions(salt_lower):
    """Try exact key and common variants. Return (list, found_bool, source_str)."""
    variants = [salt_lower]
    if salt_lower == 'amoxycillin': variants.append('amoxicillin')
    if salt_lower == 'amoxicillin': variants.append('amoxycillin')
    for key in variants:
        rows = md_index.get(key, [])
        if rows:
            for row in rows:
                try:
                    di = json.loads(row['drug_interactions'])
                    drugs = [d.strip() for d in di.get('drug', []) if d.strip()]
                    if drugs:
                        return drugs[:5], True, 'medicine_data.csv'
                except Exception:
                    pass
    # prefix search
    for key in variants:
        for idx_key, rows in md_index.items():
            if idx_key.startswith(key) and rows:
                for row in rows:
                    try:
                        di = json.loads(row['drug_interactions'])
                        drugs = [d.strip() for d in di.get('drug', []) if d.strip()]
                        if drugs:
                            return drugs[:5], True, 'medicine_data.csv'
                    except Exception:
                        pass
    # fallback to OVERRIDE known data
    for key in variants:
        if key in FALLBACK_INTERACTIONS:
            return FALLBACK_INTERACTIONS[key], False, FALLBACK_SOURCE
    return [], False, ''

# ── STEP 4: build output rows ─────────────────────────────────────────
OUT_COLS = [
    'medicine_name', 'manufacturer', 'dosage_form', 'pack_size',
    'active_ingredient_1', 'strength_1',
    'active_ingredient_2', 'strength_2',
    'uses', 'side_effects', 'habit_forming', 'therapeutic_class',
    'when_to_avoid_interactions',
    'storage_note', 'source_note',
]

output_rows = []
interaction_sources = []
empty_fields_report = []

missing_targets = [salt_name for salt_name, _, _ in TARGETS if chosen.get(salt_name.lower()) is None]
if missing_targets:
    raise SystemExit('Cannot build a complete dataset; missing medicine targets: ' + ', '.join(missing_targets))

for (salt_name, _, _) in TARGETS:
    salt_lower = salt_name.lower()
    az = chosen.get(salt_lower)
    if az is None:
        raise RuntimeError(f"Unexpected missing medicine target after validation: {salt_name}")

    ing1, str1 = parse_strength(norm(az['short_composition1']))
    uses = flatten_uses(az)
    se   = normalize_list(norm(az['Consolidated_Side_Effects']))
    form = extract_form(az['pack_size_label'])

    interactions, found_in_md, inter_src = get_interactions(salt_lower)
    interaction_sources.append((salt_name, found_in_md, inter_src, interactions))
    interactions_str = '; '.join(interactions)

    empties = []
    for field, val in [('uses', uses), ('side_effects', se),
                       ('strength_1', str1), ('when_to_avoid_interactions', interactions_str)]:
        if not val:
            empties.append(field)
    if empties:
        empty_fields_report.append((salt_name, empties))

    source_note = 'demo storage text'
    if not found_in_md and inter_src == FALLBACK_SOURCE:
        source_note = 'demo storage text; interaction: ' + FALLBACK_SOURCE

    output_rows.append({
        'medicine_name':              norm(az['name']),
        'manufacturer':               norm(az['manufacturer_name']),
        'dosage_form':                form,
        'pack_size':                  norm(az['pack_size_label']),
        'active_ingredient_1':        ing1,
        'strength_1':                 str1,
        'active_ingredient_2':        '',
        'strength_2':                 '',
        'uses':                       uses,
        'side_effects':               se,
        'habit_forming':              norm(az['Habit Forming']),
        'therapeutic_class':          norm(az['Therapeutic Class']),
        'when_to_avoid_interactions': interactions_str,
        'storage_note':               STORAGE,  # OVERRIDE
        'source_note':                source_note,
    })

# ── STEP 5: write CSV ──────────────────────────────────────────────────
with open(OUT, 'w', encoding='utf-8', newline='') as f:
    w = csv.DictWriter(f, fieldnames=OUT_COLS)
    w.writeheader()
    w.writerows(output_rows)

print(f"\nWrote {len(output_rows)} rows -> {OUT}")

# ── STEP 6: readable table ─────────────────────────────────────────────
print()
print(f"{'#':<3} {'Salt':<18} {'Form':<12} {'Strength':<12} {'Manufacturer':<42} {'Interaction src'}")
print("-" * 110)
for i, r in enumerate(output_rows, 1):
    _, found, src, _ = interaction_sources[i-1]
    isrc = 'medicine_data' if found else ('fallback' if src else 'NONE')
    print(f"{i:<3} {r['active_ingredient_1']:<18} {r['dosage_form']:<12} "
          f"{r['strength_1']:<12} {r['manufacturer'][:41]:<42} {isrc}")

# ── STEP 7: reports ───────────────────────────────────────────────────
print()
print("-- Interaction source detail --")
for salt, found, src, drugs in interaction_sources:
    status = "from medicine_data (single-ingredient)" if found else f"FALLBACK ({src})"
    print(f"  {salt:<18}: {status} -> {', '.join(drugs) if drugs else 'EMPTY'}")

print()
print("-- Empty fields --")
if empty_fields_report:
    for salt, fields in empty_fields_report:
        print(f"  {salt}: {', '.join(fields)}")
else:
    print("  None -- all fields populated")

print("\nDone.")
