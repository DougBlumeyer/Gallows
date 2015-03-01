CREATE TABLE reveals (
  id INTEGER PRIMARY KEY,
  gssd_ltr_combo TEXT NOT NULL,
  gssd_ltr CHAR(1) NOT NULL,
  board CHAR(50) NOT NULL,
  reveal_idx_sets TEXT NOT NULL
);
