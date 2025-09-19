--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Homebrew)
-- Dumped by pg_dump version 17.0

-- Started on 2025-09-19 12:02:28 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: maridapetruccelli
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO maridapetruccelli;

--
-- TOC entry 936 (class 1247 OID 18595)
-- Name: classe_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.classe_enum AS ENUM (
    'Economy',
    'Economy Premium',
    'Business'
);


ALTER TYPE public.classe_enum OWNER TO maridapetruccelli;

--
-- TOC entry 897 (class 1247 OID 18429)
-- Name: livello_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.livello_enum AS ENUM (
    'Smart',
    'Plus',
    'Premium',
    'Executive'
);


ALTER TYPE public.livello_enum OWNER TO maridapetruccelli;

--
-- TOC entry 912 (class 1247 OID 18492)
-- Name: metodo_pagamento_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.metodo_pagamento_enum AS ENUM (
    'Carta di Credito',
    'Bonifico',
    'PayPal',
    'Voucher'
);


ALTER TYPE public.metodo_pagamento_enum OWNER TO maridapetruccelli;

--
-- TOC entry 969 (class 1247 OID 18749)
-- Name: stato_biglietto_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.stato_biglietto_enum AS ENUM (
    'Emesso',
    'Checked In',
    'Terminato',
    'Rimborsato',
    'Cancellato'
);


ALTER TYPE public.stato_biglietto_enum OWNER TO maridapetruccelli;

--
-- TOC entry 963 (class 1247 OID 18727)
-- Name: stato_posto_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.stato_posto_enum AS ENUM (
    'Libero',
    'Occupato',
    'Bloccato'
);


ALTER TYPE public.stato_posto_enum OWNER TO maridapetruccelli;

--
-- TOC entry 903 (class 1247 OID 18453)
-- Name: stato_prenotazione_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.stato_prenotazione_enum AS ENUM (
    'Attiva',
    'Annullata',
    'Confermata'
);


ALTER TYPE public.stato_prenotazione_enum OWNER TO maridapetruccelli;

--
-- TOC entry 930 (class 1247 OID 18565)
-- Name: stato_segmento_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.stato_segmento_enum AS ENUM (
    'In partenza',
    'In Volo',
    'Atterrato',
    'In Ritardo',
    'Cancellato',
    'Programmato'
);


ALTER TYPE public.stato_segmento_enum OWNER TO maridapetruccelli;

--
-- TOC entry 957 (class 1247 OID 18692)
-- Name: stato_ticket_viaggio_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.stato_ticket_viaggio_enum AS ENUM (
    'Attivo',
    'Terminato',
    'Annullato'
);


ALTER TYPE public.stato_ticket_viaggio_enum OWNER TO maridapetruccelli;

--
-- TOC entry 942 (class 1247 OID 18615)
-- Name: stato_volo_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.stato_volo_enum AS ENUM (
    'Programmato',
    'In Partenza',
    'In Volo',
    'Arrivato',
    'In Ritardo',
    'Cancellato'
);


ALTER TYPE public.stato_volo_enum OWNER TO maridapetruccelli;

--
-- TOC entry 891 (class 1247 OID 18411)
-- Name: tipo_documento_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.tipo_documento_enum AS ENUM (
    'Carta Identità',
    'Passaporto',
    'Patente'
);


ALTER TYPE public.tipo_documento_enum OWNER TO maridapetruccelli;

--
-- TOC entry 978 (class 1247 OID 18813)
-- Name: tipo_variazione_enum; Type: TYPE; Schema: public; Owner: maridapetruccelli
--

CREATE TYPE public.tipo_variazione_enum AS ENUM (
    'Promozione',
    'Stagionale',
    'Operativa',
    'Supplemento',
    'Rimborso_Parziale',
    'Altro'
);


ALTER TYPE public.tipo_variazione_enum OWNER TO maridapetruccelli;

--
-- TOC entry 279 (class 1255 OID 19017)
-- Name: fn_aggiorna_stato_biglietti(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.fn_aggiorna_stato_biglietti() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE Biglietto b
  SET stato = CASE
                WHEN s.stato IN ('In partenza'::stato_segmento_enum, 'In Volo'::stato_segmento_enum)
                  THEN 'Checked In'::stato_biglietto_enum
                WHEN s.stato = 'Atterrato'::stato_segmento_enum
                  THEN 'Terminato'::stato_biglietto_enum
                WHEN s.stato = 'Cancellato'::stato_segmento_enum
                  THEN 'Cancellato'::stato_biglietto_enum
                ELSE 'Emesso'::stato_biglietto_enum
              END
  FROM Segmento s
  WHERE s.id_segmento = b.id_segmento;
END;
$$;


ALTER FUNCTION public.fn_aggiorna_stato_biglietti() OWNER TO maridapetruccelli;

--
-- TOC entry 271 (class 1255 OID 18903)
-- Name: fn_costo_totale_prenotazione(integer); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.fn_costo_totale_prenotazione(p_id_prenotazione integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_totale_ticket NUMERIC := 0;
  v_totale_accessori NUMERIC := 0;
  v_totale NUMERIC := 0;
BEGIN
  SELECT COALESCE(SUM(tv.totale_pagato), 0)
  INTO v_totale_ticket
  FROM TicketViaggio tv
  WHERE tv.id_prenotazione = p_id_prenotazione;


  SELECT COALESCE(SUM(pa.prezzo_pagato), 0)
  INTO v_totale_accessori
  FROM PagamentoAccessorio pa
  JOIN Biglietto b ON pa.id_biglietto = b.id_biglietto
  JOIN TicketViaggio tv ON b.id_ticket_viaggio = tv.id_ticket_viaggio
  WHERE tv.id_prenotazione = p_id_prenotazione;

  v_totale := v_totale_ticket + v_totale_accessori;

  RETURN v_totale;
END;
$$;


ALTER FUNCTION public.fn_costo_totale_prenotazione(p_id_prenotazione integer) OWNER TO maridapetruccelli;

--
-- TOC entry 272 (class 1255 OID 19022)
-- Name: fn_ricalcolo_prezzo_effettivo(integer); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.fn_ricalcolo_prezzo_effettivo(id_b integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
 
    UPDATE Biglietto
    SET prezzo_base = prezzo_base  
    WHERE id_biglietto = id_b;
END;
$$;


ALTER FUNCTION public.fn_ricalcolo_prezzo_effettivo(id_b integer) OWNER TO maridapetruccelli;

--
-- TOC entry 281 (class 1255 OID 19089)
-- Name: fn_sin_importi_pagamenti(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.fn_sin_importi_pagamenti() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- aggiorna ogni pagamento con l'importo attuale della sua prenotazione
  UPDATE Pagamento p
  SET importo = pr.importo_totale
  FROM Prenotazione pr
  WHERE p.id_prenotazione = pr.id_prenotazione;
END;
$$;


ALTER FUNCTION public.fn_sin_importi_pagamenti() OWNER TO maridapetruccelli;

--
-- TOC entry 284 (class 1255 OID 18989)
-- Name: fn_sin_volo_data(integer); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.fn_sin_volo_data(p_id_volo integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_primo_seg INT;
  v_ultimo_seg  INT;
BEGIN
  -- primo e ultimo segmento in base all'ordine
  SELECT id_segmento
  INTO v_primo_seg
  FROM SegmentoInVolo
  WHERE id_volo = p_id_volo
  ORDER BY ordine_segmento ASC
  LIMIT 1;

  SELECT id_segmento
  INTO v_ultimo_seg
  FROM SegmentoInVolo
  WHERE id_volo = p_id_volo
  ORDER BY ordine_segmento DESC
  LIMIT 1;

  -- se non ci sono segmenti, non faccio nulla
  IF v_primo_seg IS NULL OR v_ultimo_seg IS NULL THEN
    RETURN;
  END IF;

  -- aggiorno il volo prendendo date dal primo/ultimo segmento
  UPDATE Volo v
  SET
    data_ora_partenza_prevista  = (SELECT s.data_ora_partenza_prevista  FROM Segmento s WHERE s.id_segmento = v_primo_seg),
    data_ora_partenza_effettiva = (SELECT s.data_ora_partenza_effettiva FROM Segmento s WHERE s.id_segmento = v_primo_seg),
    data_ora_arrivo_previsto    = (SELECT s.data_ora_arrivo_previsto    FROM Segmento s WHERE s.id_segmento = v_ultimo_seg),
    data_ora_arrivo_effettivo   = (SELECT s.data_ora_arrivo_effettivo   FROM Segmento s WHERE s.id_segmento = v_ultimo_seg)
  WHERE v.id_volo = p_id_volo;
END;
$$;


ALTER FUNCTION public.fn_sin_volo_data(p_id_volo integer) OWNER TO maridapetruccelli;

--
-- TOC entry 282 (class 1255 OID 19087)
-- Name: trg_aggiorna_importo_pagamento(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_aggiorna_importo_pagamento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
  -- aggiorna tutti i pagamenti associati alla prenotazione
  UPDATE Pagamento
  SET importo = CASE
                  WHEN is_confermato = TRUE  THEN NEW.importo_totale
                  ELSE 0
                END
  WHERE id_prenotazione = NEW.id_prenotazione;

  RETURN NEW;
END;$$;


ALTER FUNCTION public.trg_aggiorna_importo_pagamento() OWNER TO maridapetruccelli;

--
-- TOC entry 257 (class 1255 OID 18885)
-- Name: trg_aggiorna_importo_prenotazione(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_aggiorna_importo_prenotazione() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_prenotazione_id INT;
BEGIN

  IF (TG_OP = 'DELETE') THEN
    v_prenotazione_id := OLD.id_prenotazione;
  ELSE
    v_prenotazione_id := NEW.id_prenotazione;
  END IF;

  UPDATE Prenotazione p
  SET importo_totale = (
    SELECT COALESCE(SUM(tv.totale_pagato), 0)
    FROM TicketViaggio tv
    WHERE tv.id_prenotazione = v_prenotazione_id
  )
  WHERE p.id_prenotazione = v_prenotazione_id;

  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;


ALTER FUNCTION public.trg_aggiorna_importo_prenotazione() OWNER TO maridapetruccelli;

--
-- TOC entry 258 (class 1255 OID 18883)
-- Name: trg_aggiorna_importo_ticket_viaggio(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_aggiorna_importo_ticket_viaggio() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_ticket_id INT;
BEGIN

  IF (TG_OP = 'DELETE') THEN
    v_ticket_id := OLD.id_ticket_viaggio;
  ELSE
    v_ticket_id := NEW.id_ticket_viaggio;
  END IF;


  UPDATE TicketViaggio tv
  SET totale_pagato = (
    SELECT COALESCE(SUM(b.prezzo_effettivo), 0)
    FROM Biglietto b
    WHERE b.id_ticket_viaggio = v_ticket_id
  )
  WHERE tv.id_ticket_viaggio = v_ticket_id;


  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;


ALTER FUNCTION public.trg_aggiorna_importo_ticket_viaggio() OWNER TO maridapetruccelli;

--
-- TOC entry 277 (class 1255 OID 19027)
-- Name: trg_aggiorna_stato_biglietto(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_aggiorna_stato_biglietto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM fn_aggiorna_stato_biglietti();  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_aggiorna_stato_biglietto() OWNER TO maridapetruccelli;

--
-- TOC entry 283 (class 1255 OID 19085)
-- Name: trg_aggiorna_stato_prenotazione(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_aggiorna_stato_prenotazione() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_prenotazione_id INT;
  v_has_confirmed BOOLEAN;
BEGIN
  -- id_prenotazione dipende dal tipo di operazione
  IF (TG_OP = 'DELETE') THEN
    v_prenotazione_id := OLD.id_prenotazione;
  ELSE
    v_prenotazione_id := NEW.id_prenotazione;
  END IF;

  -- controlla se esiste almeno un pagamento confermato
  SELECT EXISTS (
    SELECT 1
    FROM Pagamento p
    WHERE p.id_prenotazione = v_prenotazione_id
      AND p.is_confermato = TRUE
  ) INTO v_has_confirmed;

  -- aggiorna lo stato
  UPDATE Prenotazione
SET stato = CASE 
              WHEN v_has_confirmed THEN 'Confermata'::stato_prenotazione_enum
              ELSE 'Attiva'::stato_prenotazione_enum
            END
WHERE id_prenotazione = v_prenotazione_id;
  -- ritorna il record corretto
  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;


ALTER FUNCTION public.trg_aggiorna_stato_prenotazione() OWNER TO maridapetruccelli;

--
-- TOC entry 273 (class 1255 OID 19020)
-- Name: trg_calc_prezzo_effettivo_biglietto(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_calc_prezzo_effettivo_biglietto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    v_percentuale NUMERIC := 0;
BEGIN
    -- Se non c’è variazione associata al biglietto → prezzo effettivo = prezzo base
    IF NEW.id_variazione IS NULL THEN
        NEW.prezzo_effettivo := NEW.prezzo_base;

    ELSE
        -- Recupero la percentuale della variazione indicata dal biglietto
        SELECT percentuale
        INTO v_percentuale
        FROM VariazionePrezzo
        WHERE id_variazione = NEW.id_variazione;

        v_percentuale := COALESCE(v_percentuale, 0);

        -- Calcolo prezzo_effettivo: positivo = aumento, negativo = sconto
        NEW.prezzo_effettivo :=
            ROUND(GREATEST(NEW.prezzo_base * (1 + (v_percentuale / 100.0)), 0), 2);
    END IF;

    RETURN NEW;
END;$$;


ALTER FUNCTION public.trg_calc_prezzo_effettivo_biglietto() OWNER TO maridapetruccelli;

--
-- TOC entry 286 (class 1255 OID 19133)
-- Name: trg_calcola_durata_volo(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_calcola_durata_volo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- calcola la durata solo se entrambi gli orari sono valorizzati
  IF NEW.data_ora_arrivo_previsto IS NOT NULL
     AND NEW.data_ora_partenza_prevista IS NOT NULL THEN
    NEW.durata := NEW.data_ora_arrivo_previsto - NEW.data_ora_partenza_prevista;
  ELSE
    NEW.durata := NULL;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_calcola_durata_volo() OWNER TO maridapetruccelli;

--
-- TOC entry 274 (class 1255 OID 19090)
-- Name: trg_calcola_ritardo_volo(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_calcola_ritardo_volo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- aggiorna il ritardo solo se arrivo effettivo e previsto sono valorizzati
  IF NEW.data_ora_arrivo_effettivo IS NOT NULL 
     AND NEW.data_ora_arrivo_previsto IS NOT NULL THEN
     
    NEW.ritardo_totale :=
      EXTRACT(EPOCH FROM (NEW.data_ora_arrivo_effettivo - NEW.data_ora_arrivo_previsto))::INT / 60;
  ELSE
    NEW.ritardo_totale := NULL;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_calcola_ritardo_volo() OWNER TO maridapetruccelli;

--
-- TOC entry 285 (class 1255 OID 19130)
-- Name: trg_check_documento_valido(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_check_documento_valido() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_data_arrivo   timestamp;
  v_scadenza      date;
BEGIN
  -- prendo la data di arrivo prevista del segmento
  SELECT s.data_ora_arrivo_previsto
  INTO v_data_arrivo
  FROM Segmento s
  WHERE s.id_segmento = NEW.id_segmento;

  -- prendo la data di scadenza documento del passeggero
  SELECT p.scadenza_documento
  INTO v_scadenza
  FROM TicketViaggio tv
  JOIN Passeggero p ON p.id_passeggero = tv.id_passeggero
  WHERE tv.id_ticket_viaggio = NEW.id_ticket_viaggio;

  -- se il documento scade prima dell’arrivo previsto → blocca inserimento
  IF v_scadenza < v_data_arrivo::date THEN
    RAISE EXCEPTION 'Documento scaduto (scadenza %, arrivo previsto %)', v_scadenza, v_data_arrivo::date;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_check_documento_valido() OWNER TO maridapetruccelli;

--
-- TOC entry 259 (class 1255 OID 18889)
-- Name: trg_check_prenotazione_posti(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_check_prenotazione_posti() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_stato TEXT;
BEGIN

  SELECT stato INTO v_stato
  FROM Posto
  WHERE id_posto = NEW.id_posto
    AND id_segmento = NEW.id_segmento;

  IF v_stato IS NULL THEN
    RAISE EXCEPTION 'Il posto % non esiste per il segmento %',
      NEW.id_posto, NEW.id_segmento;
  END IF;

  IF v_stato <> 'Libero' THEN
    RAISE EXCEPTION 'Il posto % del segmento % è già occupato',
      NEW.id_posto, NEW.id_segmento;
  END IF;


  UPDATE Posto
  SET stato = 'Occupato'
  WHERE id_posto = NEW.id_posto
    AND id_segmento = NEW.id_segmento;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_check_prenotazione_posti() OWNER TO maridapetruccelli;

--
-- TOC entry 275 (class 1255 OID 18887)
-- Name: trg_check_ticket_biglietto(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_check_ticket_biglietto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id_prenotazione INT;
  v_id_passeggero   INT;
  v_cnt             INT;
BEGIN
  -- recupero passeggero e prenotazione dal ticket associato al biglietto
  SELECT tk.id_prenotazione, tk.id_passeggero
    INTO v_id_prenotazione, v_id_passeggero
  FROM TicketViaggio tk
  WHERE tk.id_ticket_viaggio = NEW.id_ticket_viaggio;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TicketViaggio % inesistente', NEW.id_ticket_viaggio;
  END IF;

  -- esempio di controllo: il passeggero del ticket deve esistere (ridondante ma esplicito)
  SELECT COUNT(*) INTO v_cnt
  FROM Passeggero p
  WHERE p.id_passeggero = v_id_passeggero;

  IF v_cnt = 0 THEN
    RAISE EXCEPTION 'Passeggero % inesistente per TicketViaggio %',
                    v_id_passeggero, NEW.id_ticket_viaggio;
  END IF;

 

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_check_ticket_biglietto() OWNER TO maridapetruccelli;

--
-- TOC entry 276 (class 1255 OID 18992)
-- Name: trg_segmento_sin_voli(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_segmento_sin_voli() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_seg INT := COALESCE(NEW.id_segmento, OLD.id_segmento);
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT id_volo
    FROM SegmentoInVolo
    WHERE id_segmento = v_seg
  LOOP
    PERFORM fn_sin_volo_data(r.id_volo);
  END LOOP;

  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.trg_segmento_sin_voli() OWNER TO maridapetruccelli;

--
-- TOC entry 278 (class 1255 OID 18990)
-- Name: trg_segmentoinvolo_sin(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_segmentoinvolo_sin() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_volo INT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_volo := OLD.id_volo;
  ELSE
    v_volo := NEW.id_volo;
  END IF;

  PERFORM fn_sin_volo_date(v_volo);
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.trg_segmentoinvolo_sin() OWNER TO maridapetruccelli;

--
-- TOC entry 280 (class 1255 OID 19018)
-- Name: trg_storico_su_biglietto(); Type: FUNCTION; Schema: public; Owner: maridapetruccelli
--

CREATE FUNCTION public.trg_storico_su_biglietto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_old_pax int;
  v_new_pax int;
BEGIN
  -- passeggero associato al ticket precedente/nuovo
  SELECT id_passeggero INTO v_old_pax FROM TicketViaggio WHERE id_ticket_viaggio = OLD.id_ticket_viaggio;
  SELECT id_passeggero INTO v_new_pax FROM TicketViaggio WHERE id_ticket_viaggio = NEW.id_ticket_viaggio;

  IF v_new_pax IS DISTINCT FROM v_old_pax THEN
    INSERT INTO StoricoBiglietto
      (id_storico_biglietto, id_biglietto, id_vecchio_passeggero, id_nuovo_passeggero, data_modifica, motivo)
    VALUES
      (nextval('storico_biglietto_id_seq'), NEW.id_biglietto, v_old_pax, v_new_pax, now(), 'Cambio passeggero via cambio ticket');
    UPDATE Biglietto SET is_modificato = TRUE WHERE id_biglietto = NEW.id_biglietto;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_storico_su_biglietto() OWNER TO maridapetruccelli;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 18518)
-- Name: accessorio; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.accessorio (
    id_accessorio integer NOT NULL,
    nome character varying(50) NOT NULL,
    descrizione text,
    prezzo numeric(10,2) NOT NULL,
    is_disponibile boolean DEFAULT true,
    peso_massimo numeric(5,2),
    dimensioni_massime character varying(50),
    CONSTRAINT accessorio_peso_massimo_check CHECK ((peso_massimo >= (0)::numeric)),
    CONSTRAINT accessorio_prezzo_check CHECK ((prezzo >= (0)::numeric))
);


ALTER TABLE public.accessorio OWNER TO maridapetruccelli;

--
-- TOC entry 220 (class 1259 OID 18517)
-- Name: accessorio_id_accessorio_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.accessorio_id_accessorio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.accessorio_id_accessorio_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4093 (class 0 OID 0)
-- Dependencies: 220
-- Name: accessorio_id_accessorio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.accessorio_id_accessorio_seq OWNED BY public.accessorio.id_accessorio;


--
-- TOC entry 223 (class 1259 OID 18536)
-- Name: aereo; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.aereo (
    matricola character varying(20) NOT NULL,
    modello character varying(50) NOT NULL,
    capacita_passeggeri integer NOT NULL,
    anno_costruzione integer NOT NULL,
    CONSTRAINT aereo_capacita_passeggeri_check CHECK ((capacita_passeggeri > 0)),
    CONSTRAINT chk_anno_costruzione CHECK (((anno_costruzione > 1970) AND ((anno_costruzione)::numeric <= EXTRACT(year FROM CURRENT_DATE))))
);


ALTER TABLE public.aereo OWNER TO maridapetruccelli;

--
-- TOC entry 222 (class 1259 OID 18531)
-- Name: aeroporto; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.aeroporto (
    codice_iata character(3) NOT NULL,
    nome character varying(100) NOT NULL,
    "città" character varying(100) NOT NULL,
    stato character varying(100) NOT NULL,
    fuso_orario character varying(50) NOT NULL
);


ALTER TABLE public.aeroporto OWNER TO maridapetruccelli;

--
-- TOC entry 241 (class 1259 OID 18760)
-- Name: biglietto; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.biglietto (
    id_biglietto integer NOT NULL,
    codice_biglietto character varying(10) NOT NULL,
    id_ticket_viaggio integer NOT NULL,
    id_segmento integer NOT NULL,
    id_posto integer,
    classe public.classe_enum NOT NULL,
    prezzo_base numeric(10,2) NOT NULL,
    prezzo_effettivo numeric(10,2),
    is_modificato boolean DEFAULT false NOT NULL,
    stato public.stato_biglietto_enum NOT NULL,
    id_variazione integer,
    CONSTRAINT biglietto_prezzo_base_check CHECK ((prezzo_base >= (0)::numeric)),
    CONSTRAINT biglietto_prezzo_effettivo_check CHECK ((prezzo_effettivo >= (0)::numeric))
);


ALTER TABLE public.biglietto OWNER TO maridapetruccelli;

--
-- TOC entry 240 (class 1259 OID 18759)
-- Name: biglietto_id_biglietto_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.biglietto_id_biglietto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.biglietto_id_biglietto_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4094 (class 0 OID 0)
-- Dependencies: 240
-- Name: biglietto_id_biglietto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.biglietto_id_biglietto_seq OWNED BY public.biglietto.id_biglietto;


--
-- TOC entry 248 (class 1259 OID 19014)
-- Name: bk_code_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.bk_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bk_code_seq OWNER TO maridapetruccelli;

--
-- TOC entry 229 (class 1259 OID 18602)
-- Name: classeprezzo; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.classeprezzo (
    id_classe_prezzo integer NOT NULL,
    id_segmento integer NOT NULL,
    classe public.classe_enum NOT NULL,
    prezzo numeric(10,2) NOT NULL,
    CONSTRAINT classeprezzo_prezzo_check CHECK ((prezzo >= (0)::numeric))
);


ALTER TABLE public.classeprezzo OWNER TO maridapetruccelli;

--
-- TOC entry 228 (class 1259 OID 18601)
-- Name: classeprezzo_id_classe_prezzo_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.classeprezzo_id_classe_prezzo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classeprezzo_id_classe_prezzo_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4095 (class 0 OID 0)
-- Dependencies: 228
-- Name: classeprezzo_id_classe_prezzo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.classeprezzo_id_classe_prezzo_seq OWNED BY public.classeprezzo.id_classe_prezzo;


--
-- TOC entry 213 (class 1259 OID 18437)
-- Name: fidelizzatovolare; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.fidelizzatovolare (
    codice_volare character varying(10) NOT NULL,
    id_passeggero integer NOT NULL,
    data_adesione date NOT NULL,
    punti integer DEFAULT 0,
    livello public.livello_enum NOT NULL,
    CONSTRAINT chk_data_adesione CHECK ((data_adesione <= CURRENT_DATE)),
    CONSTRAINT chk_punti CHECK ((punti >= 0))
);


ALTER TABLE public.fidelizzatovolare OWNER TO maridapetruccelli;

--
-- TOC entry 219 (class 1259 OID 18502)
-- Name: pagamento; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.pagamento (
    id_pagamento integer NOT NULL,
    id_prenotazione integer NOT NULL,
    data_pagamento date DEFAULT CURRENT_DATE NOT NULL,
    metodo_pagamento public.metodo_pagamento_enum NOT NULL,
    importo numeric(10,2),
    is_confermato boolean DEFAULT false,
    CONSTRAINT chk_data_pagamento CHECK ((data_pagamento <= CURRENT_DATE)),
    CONSTRAINT chk_importo CHECK ((importo >= (0)::numeric))
);


ALTER TABLE public.pagamento OWNER TO maridapetruccelli;

--
-- TOC entry 218 (class 1259 OID 18501)
-- Name: pagamento_id_pagamento_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.pagamento_id_pagamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagamento_id_pagamento_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4096 (class 0 OID 0)
-- Dependencies: 218
-- Name: pagamento_id_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.pagamento_id_pagamento_seq OWNED BY public.pagamento.id_pagamento;


--
-- TOC entry 243 (class 1259 OID 18793)
-- Name: pagamentoaccessorio; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.pagamentoaccessorio (
    id_pagamento_accessorio integer NOT NULL,
    id_biglietto integer NOT NULL,
    id_accessorio integer NOT NULL,
    "quantità" integer NOT NULL,
    data_pagamento date DEFAULT CURRENT_DATE,
    prezzo_pagato numeric(10,2) NOT NULL,
    metodo_pagamento public.metodo_pagamento_enum NOT NULL,
    CONSTRAINT pagamentoaccessorio_prezzo_pagato_check CHECK ((prezzo_pagato >= (0)::numeric)),
    CONSTRAINT "pagamentoaccessorio_quantità_check" CHECK (("quantità" >= 0))
);


ALTER TABLE public.pagamentoaccessorio OWNER TO maridapetruccelli;

--
-- TOC entry 242 (class 1259 OID 18792)
-- Name: pagamentoaccessorio_id_pagamento_accessorio_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.pagamentoaccessorio_id_pagamento_accessorio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagamentoaccessorio_id_pagamento_accessorio_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4097 (class 0 OID 0)
-- Dependencies: 242
-- Name: pagamentoaccessorio_id_pagamento_accessorio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.pagamentoaccessorio_id_pagamento_accessorio_seq OWNED BY public.pagamentoaccessorio.id_pagamento_accessorio;


--
-- TOC entry 212 (class 1259 OID 18418)
-- Name: passeggero; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.passeggero (
    id_passeggero integer NOT NULL,
    nome character varying(50) NOT NULL,
    cognome character varying(50) NOT NULL,
    data_nascita date NOT NULL,
    tipo_documento public.tipo_documento_enum NOT NULL,
    numero_documento character varying(30) NOT NULL,
    scadenza_documento date NOT NULL,
    CONSTRAINT chk_data_nascita CHECK ((data_nascita < CURRENT_DATE)),
    CONSTRAINT chk_scadenza_documento CHECK ((scadenza_documento > CURRENT_DATE))
);


ALTER TABLE public.passeggero OWNER TO maridapetruccelli;

--
-- TOC entry 211 (class 1259 OID 18417)
-- Name: passeggero_id_passeggero_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.passeggero_id_passeggero_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.passeggero_id_passeggero_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4098 (class 0 OID 0)
-- Dependencies: 211
-- Name: passeggero_id_passeggero_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.passeggero_id_passeggero_seq OWNED BY public.passeggero.id_passeggero;


--
-- TOC entry 239 (class 1259 OID 18734)
-- Name: posto; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.posto (
    id_posto integer NOT NULL,
    id_segmento integer NOT NULL,
    numero_posto character varying(5) NOT NULL,
    classe public.classe_enum NOT NULL,
    stato public.stato_posto_enum DEFAULT 'Libero'::public.stato_posto_enum NOT NULL
);


ALTER TABLE public.posto OWNER TO maridapetruccelli;

--
-- TOC entry 238 (class 1259 OID 18733)
-- Name: posto_id_posto_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.posto_id_posto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posto_id_posto_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4099 (class 0 OID 0)
-- Dependencies: 238
-- Name: posto_id_posto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.posto_id_posto_seq OWNED BY public.posto.id_posto;


--
-- TOC entry 215 (class 1259 OID 18460)
-- Name: prenotazione; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.prenotazione (
    id_prenotazione integer NOT NULL,
    codice_prenotazione character varying(20) NOT NULL,
    id_utente integer,
    data_prenotazione date DEFAULT CURRENT_DATE NOT NULL,
    stato public.stato_prenotazione_enum NOT NULL,
    importo_totale numeric(10,2),
    CONSTRAINT chk_data_prenotazione CHECK ((data_prenotazione <= CURRENT_DATE)),
    CONSTRAINT chk_importo CHECK (((importo_totale IS NULL) OR (importo_totale >= (0)::numeric)))
);


ALTER TABLE public.prenotazione OWNER TO maridapetruccelli;

--
-- TOC entry 214 (class 1259 OID 18459)
-- Name: prenotazione_id_prenotazione_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.prenotazione_id_prenotazione_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prenotazione_id_prenotazione_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4100 (class 0 OID 0)
-- Dependencies: 214
-- Name: prenotazione_id_prenotazione_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.prenotazione_id_prenotazione_seq OWNED BY public.prenotazione.id_prenotazione;


--
-- TOC entry 235 (class 1259 OID 18675)
-- Name: prenotazionevolo; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.prenotazionevolo (
    id_prenotazione integer NOT NULL,
    id_volo integer NOT NULL
);


ALTER TABLE public.prenotazionevolo OWNER TO maridapetruccelli;

--
-- TOC entry 233 (class 1259 OID 18638)
-- Name: scalo; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.scalo (
    id_scalo integer NOT NULL,
    id_volo integer NOT NULL,
    codice_iata character(3) NOT NULL,
    ordine integer NOT NULL,
    tempo_attesa interval,
    CONSTRAINT scalo_ordine_check CHECK ((ordine >= 1))
);


ALTER TABLE public.scalo OWNER TO maridapetruccelli;

--
-- TOC entry 232 (class 1259 OID 18637)
-- Name: scalo_id_scalo_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.scalo_id_scalo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scalo_id_scalo_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4101 (class 0 OID 0)
-- Dependencies: 232
-- Name: scalo_id_scalo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.scalo_id_scalo_seq OWNED BY public.scalo.id_scalo;


--
-- TOC entry 227 (class 1259 OID 18576)
-- Name: segmento; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.segmento (
    id_segmento integer NOT NULL,
    id_tratta integer NOT NULL,
    matricola_aereo character varying(20) NOT NULL,
    codice_volo character varying(15) NOT NULL,
    data_ora_partenza_prevista timestamp without time zone NOT NULL,
    data_ora_arrivo_previsto timestamp without time zone NOT NULL,
    data_ora_partenza_effettiva timestamp without time zone,
    data_ora_arrivo_effettivo timestamp without time zone,
    gate_partenza character varying(5),
    gate_arrivo character varying(5),
    stato public.stato_segmento_enum NOT NULL,
    CONSTRAINT chk_previsti_coerenti CHECK ((data_ora_partenza_prevista < data_ora_arrivo_previsto))
);


ALTER TABLE public.segmento OWNER TO maridapetruccelli;

--
-- TOC entry 226 (class 1259 OID 18575)
-- Name: segmento_id_segmento_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.segmento_id_segmento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.segmento_id_segmento_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4102 (class 0 OID 0)
-- Dependencies: 226
-- Name: segmento_id_segmento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.segmento_id_segmento_seq OWNED BY public.segmento.id_segmento;


--
-- TOC entry 234 (class 1259 OID 18657)
-- Name: segmentoinvolo; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.segmentoinvolo (
    id_segmento integer NOT NULL,
    id_volo integer NOT NULL,
    ordine_segmento integer NOT NULL,
    CONSTRAINT segmentoinvolo_ordine_segmento_check CHECK ((ordine_segmento >= 1))
);


ALTER TABLE public.segmentoinvolo OWNER TO maridapetruccelli;

--
-- TOC entry 247 (class 1259 OID 18843)
-- Name: storicobiglietto; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.storicobiglietto (
    id_storico_biglietto integer NOT NULL,
    id_biglietto integer NOT NULL,
    id_vecchio_passeggero integer NOT NULL,
    id_nuovo_passeggero integer NOT NULL,
    data_modifica date DEFAULT CURRENT_DATE NOT NULL,
    motivo text NOT NULL,
    CONSTRAINT chk_data_modifica CHECK ((data_modifica <= CURRENT_DATE)),
    CONSTRAINT chk_passeggeri_diversi CHECK ((id_vecchio_passeggero <> id_nuovo_passeggero))
);


ALTER TABLE public.storicobiglietto OWNER TO maridapetruccelli;

--
-- TOC entry 246 (class 1259 OID 18842)
-- Name: storicobiglietto_id_storico_biglietto_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.storicobiglietto_id_storico_biglietto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.storicobiglietto_id_storico_biglietto_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4103 (class 0 OID 0)
-- Dependencies: 246
-- Name: storicobiglietto_id_storico_biglietto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.storicobiglietto_id_storico_biglietto_seq OWNED BY public.storicobiglietto.id_storico_biglietto;


--
-- TOC entry 217 (class 1259 OID 18477)
-- Name: storicoprenotazione; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.storicoprenotazione (
    id_storico_prenotazione integer NOT NULL,
    id_prenotazione integer NOT NULL,
    data_modifica date DEFAULT CURRENT_DATE NOT NULL,
    note text
);


ALTER TABLE public.storicoprenotazione OWNER TO maridapetruccelli;

--
-- TOC entry 216 (class 1259 OID 18476)
-- Name: storicoprenotazione_id_storico_prenotazione_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.storicoprenotazione_id_storico_prenotazione_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.storicoprenotazione_id_storico_prenotazione_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4104 (class 0 OID 0)
-- Dependencies: 216
-- Name: storicoprenotazione_id_storico_prenotazione_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.storicoprenotazione_id_storico_prenotazione_seq OWNED BY public.storicoprenotazione.id_storico_prenotazione;


--
-- TOC entry 237 (class 1259 OID 18700)
-- Name: ticketviaggio; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.ticketviaggio (
    id_ticket_viaggio integer NOT NULL,
    codice_tk character varying(7) NOT NULL,
    id_prenotazione integer NOT NULL,
    id_passeggero integer NOT NULL,
    id_volo integer NOT NULL,
    data_emissione date DEFAULT CURRENT_DATE NOT NULL,
    stato public.stato_ticket_viaggio_enum NOT NULL,
    totale_pagato numeric(10,2),
    CONSTRAINT chk_data_emissione CHECK ((data_emissione <= CURRENT_DATE)),
    CONSTRAINT chk_totale_pagato CHECK (((totale_pagato IS NULL) OR (totale_pagato >= (0)::numeric)))
);


ALTER TABLE public.ticketviaggio OWNER TO maridapetruccelli;

--
-- TOC entry 236 (class 1259 OID 18699)
-- Name: ticketviaggio_id_ticket_viaggio_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.ticketviaggio_id_ticket_viaggio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ticketviaggio_id_ticket_viaggio_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4105 (class 0 OID 0)
-- Dependencies: 236
-- Name: ticketviaggio_id_ticket_viaggio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.ticketviaggio_id_ticket_viaggio_seq OWNED BY public.ticketviaggio.id_ticket_viaggio;


--
-- TOC entry 225 (class 1259 OID 18544)
-- Name: tratta; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.tratta (
    id_tratta integer NOT NULL,
    codice_rotta character varying(10) NOT NULL,
    codice_iata_partenza character(3) NOT NULL,
    codice_iata_arrivo character(3) NOT NULL,
    durata_media interval NOT NULL,
    CONSTRAINT chk_tratta_aeroporti_differenti CHECK ((codice_iata_partenza <> codice_iata_arrivo))
);


ALTER TABLE public.tratta OWNER TO maridapetruccelli;

--
-- TOC entry 224 (class 1259 OID 18543)
-- Name: tratta_id_tratta_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.tratta_id_tratta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tratta_id_tratta_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4106 (class 0 OID 0)
-- Dependencies: 224
-- Name: tratta_id_tratta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.tratta_id_tratta_seq OWNED BY public.tratta.id_tratta;


--
-- TOC entry 210 (class 1259 OID 18400)
-- Name: utente; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.utente (
    id_utente integer NOT NULL,
    nome character varying(50) NOT NULL,
    cognome character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    telefono character varying(20),
    is_registrato boolean DEFAULT false,
    password character varying(100),
    data_registrazione date,
    CONSTRAINT chk_registrato_password_data CHECK ((((is_registrato = true) AND (password IS NOT NULL) AND (data_registrazione IS NOT NULL)) OR ((is_registrato = false) AND (password IS NULL) AND (data_registrazione IS NULL))))
);


ALTER TABLE public.utente OWNER TO maridapetruccelli;

--
-- TOC entry 209 (class 1259 OID 18399)
-- Name: utente_id_utente_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.utente_id_utente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.utente_id_utente_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4107 (class 0 OID 0)
-- Dependencies: 209
-- Name: utente_id_utente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.utente_id_utente_seq OWNED BY public.utente.id_utente;


--
-- TOC entry 245 (class 1259 OID 18826)
-- Name: variazioneprezzo; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.variazioneprezzo (
    id_variazione integer NOT NULL,
    tipo_variazione public.tipo_variazione_enum NOT NULL,
    descrizione text,
    percentuale numeric(5,2),
    importo_variazione numeric(10,2),
    data_inizio_variazione date NOT NULL,
    data_fine_variazione date NOT NULL,
    CONSTRAINT chk_date_variazione CHECK ((data_inizio_variazione < data_fine_variazione))
);


ALTER TABLE public.variazioneprezzo OWNER TO maridapetruccelli;

--
-- TOC entry 244 (class 1259 OID 18825)
-- Name: variazioneprezzo_id_variazione_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.variazioneprezzo_id_variazione_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.variazioneprezzo_id_variazione_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4108 (class 0 OID 0)
-- Dependencies: 244
-- Name: variazioneprezzo_id_variazione_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.variazioneprezzo_id_variazione_seq OWNED BY public.variazioneprezzo.id_variazione;


--
-- TOC entry 231 (class 1259 OID 18628)
-- Name: volo; Type: TABLE; Schema: public; Owner: maridapetruccelli
--

CREATE TABLE public.volo (
    id_volo integer NOT NULL,
    data_ora_partenza_prevista timestamp without time zone,
    data_ora_arrivo_previsto timestamp without time zone,
    durata interval,
    data_ora_partenza_effettiva timestamp without time zone,
    data_ora_arrivo_effettivo timestamp without time zone,
    ritardo_totale integer,
    stato public.stato_volo_enum,
    CONSTRAINT chk_effettivi CHECK (((data_ora_partenza_effettiva IS NULL) OR (data_ora_arrivo_effettivo IS NULL) OR (data_ora_partenza_effettiva < data_ora_arrivo_effettivo))),
    CONSTRAINT chk_previsti CHECK (((data_ora_partenza_prevista IS NULL) OR (data_ora_arrivo_previsto IS NULL) OR (data_ora_partenza_prevista < data_ora_arrivo_previsto))),
    CONSTRAINT chk_ritardo_nonneg CHECK (((ritardo_totale IS NULL) OR (ritardo_totale >= 0)))
);


ALTER TABLE public.volo OWNER TO maridapetruccelli;

--
-- TOC entry 230 (class 1259 OID 18627)
-- Name: volo_id_volo_seq; Type: SEQUENCE; Schema: public; Owner: maridapetruccelli
--

CREATE SEQUENCE public.volo_id_volo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.volo_id_volo_seq OWNER TO maridapetruccelli;

--
-- TOC entry 4109 (class 0 OID 0)
-- Dependencies: 230
-- Name: volo_id_volo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maridapetruccelli
--

ALTER SEQUENCE public.volo_id_volo_seq OWNED BY public.volo.id_volo;


--
-- TOC entry 249 (class 1259 OID 19041)
-- Name: vw_biglietti_passeggero; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_biglietti_passeggero AS
 SELECT p.id_passeggero,
    (((p.nome)::text || ' '::text) || (p.cognome)::text) AS passeggero,
    b.id_biglietto,
    b.codice_biglietto,
    s.id_segmento,
    s.codice_volo,
    s.data_ora_partenza_prevista,
    s.data_ora_arrivo_previsto,
    po.numero_posto,
    po.classe AS classe_posto,
    b.classe AS classe_biglietto,
    b.prezzo_effettivo,
    b.stato
   FROM ((((public.biglietto b
     JOIN public.ticketviaggio t ON ((b.id_ticket_viaggio = t.id_ticket_viaggio)))
     JOIN public.passeggero p ON ((t.id_passeggero = p.id_passeggero)))
     JOIN public.segmento s ON ((b.id_segmento = s.id_segmento)))
     JOIN public.posto po ON ((b.id_posto = po.id_posto)));


ALTER VIEW public.vw_biglietti_passeggero OWNER TO maridapetruccelli;

--
-- TOC entry 252 (class 1259 OID 19064)
-- Name: vw_passeggeri_fidelizzati; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_passeggeri_fidelizzati AS
 SELECT p.id_passeggero,
    p.nome,
    p.cognome,
    p.data_nascita,
    p.tipo_documento,
    p.numero_documento,
    p.scadenza_documento,
    fv.codice_volare,
    fv.data_adesione,
    fv.livello,
    fv.punti
   FROM (public.fidelizzatovolare fv
     JOIN public.passeggero p ON ((p.id_passeggero = fv.id_passeggero)));


ALTER VIEW public.vw_passeggeri_fidelizzati OWNER TO maridapetruccelli;

--
-- TOC entry 254 (class 1259 OID 19106)
-- Name: vw_posti_disponibili; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_posti_disponibili AS
 SELECT s.id_segmento,
    s.codice_volo,
    s.data_ora_partenza_prevista,
    p.id_posto,
    p.numero_posto,
    p.classe,
    p.stato
   FROM (public.posto p
     JOIN public.segmento s ON ((p.id_segmento = s.id_segmento)))
  WHERE (p.stato = 'Libero'::public.stato_posto_enum);


ALTER VIEW public.vw_posti_disponibili OWNER TO maridapetruccelli;

--
-- TOC entry 255 (class 1259 OID 19115)
-- Name: vw_saldi_prenotazioni; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_saldi_prenotazioni AS
 WITH pagamenti_ok AS (
         SELECT pagamento.id_prenotazione,
            sum(pagamento.importo) AS pagato
           FROM public.pagamento
          WHERE pagamento.is_confermato
          GROUP BY pagamento.id_prenotazione
        ), accessori_ok AS (
         SELECT tv.id_prenotazione,
            sum((pa.prezzo_pagato * (COALESCE(pa."quantità", 1))::numeric)) AS accessori
           FROM ((public.pagamentoaccessorio pa
             JOIN public.biglietto b USING (id_biglietto))
             JOIN public.ticketviaggio tv ON ((tv.id_ticket_viaggio = b.id_ticket_viaggio)))
          GROUP BY tv.id_prenotazione
        ), conteggio AS (
         SELECT t.id_prenotazione,
            count(DISTINCT b.id_biglietto) AS n_biglietti
           FROM (public.ticketviaggio t
             JOIN public.biglietto b ON ((b.id_ticket_viaggio = t.id_ticket_viaggio)))
          GROUP BY t.id_prenotazione
        )
 SELECT pr.id_prenotazione,
    pr.codice_prenotazione,
    pr.id_utente,
    pr.data_prenotazione,
    pr.stato,
    COALESCE(c.n_biglietti, (0)::bigint) AS numero_biglietti,
    pr.importo_totale AS totale_prenotazione,
    COALESCE(a.accessori, (0)::numeric) AS totale_accessori,
    COALESCE(p.pagato, (0)::numeric) AS totale_pagato
   FROM (((public.prenotazione pr
     LEFT JOIN pagamenti_ok p ON ((p.id_prenotazione = pr.id_prenotazione)))
     LEFT JOIN accessori_ok a ON ((a.id_prenotazione = pr.id_prenotazione)))
     LEFT JOIN conteggio c ON ((c.id_prenotazione = pr.id_prenotazione)));


ALTER VIEW public.vw_saldi_prenotazioni OWNER TO maridapetruccelli;

--
-- TOC entry 256 (class 1259 OID 19124)
-- Name: vw_scali_contemporaneri_aeroporto; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_scali_contemporaneri_aeroporto AS
 WITH scalitemporizzati AS (
         SELECT s.id_volo,
            s.codice_iata,
            s.ordine,
            COALESCE(seg.data_ora_arrivo_effettivo, seg.data_ora_arrivo_previsto) AS inizio_sosta,
            (COALESCE(seg.data_ora_arrivo_effettivo, seg.data_ora_arrivo_previsto) + ((s.tempo_attesa || ' minutes'::text))::interval) AS fine_sosta
           FROM ((public.scalo s
             JOIN public.segmentoinvolo siv ON (((siv.id_volo = s.id_volo) AND (siv.ordine_segmento = s.ordine))))
             JOIN public.segmento seg ON ((seg.id_segmento = siv.id_segmento)))
        )
 SELECT a.codice_iata AS aeroporto_codice,
    ap.nome AS aeroporto_nome,
    a.id_volo AS id_volo_1,
    b.id_volo AS id_volo_2,
    a.inizio_sosta AS inizio_volo_1,
    a.fine_sosta AS fine_volo_1,
    b.inizio_sosta AS inizio_volo_2,
    b.fine_sosta AS fine_volo_2
   FROM ((scalitemporizzati a
     JOIN scalitemporizzati b ON (((a.codice_iata = b.codice_iata) AND (a.id_volo < b.id_volo) AND (a.inizio_sosta < b.fine_sosta) AND (b.inizio_sosta < a.fine_sosta))))
     LEFT JOIN public.aeroporto ap ON ((ap.codice_iata = a.codice_iata)));


ALTER VIEW public.vw_scali_contemporaneri_aeroporto OWNER TO maridapetruccelli;

--
-- TOC entry 253 (class 1259 OID 19068)
-- Name: vw_spesa_totale_utente; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_spesa_totale_utente AS
 SELECT u.id_utente,
    u.nome,
    u.cognome,
    u.email,
    count(DISTINCT pr.id_prenotazione) AS numero_prenotazioni,
    COALESCE(sum(pr.importo_totale), (0)::numeric) AS spesa_prenotazioni,
    COALESCE(sum(pg.importo), (0)::numeric) AS spesa_pagamenti,
    (COALESCE(sum(pr.importo_totale), (0)::numeric) + COALESCE(sum(pg.importo), (0)::numeric)) AS spesa_totale
   FROM ((public.utente u
     LEFT JOIN public.prenotazione pr ON ((pr.id_utente = u.id_utente)))
     LEFT JOIN public.pagamento pg ON (((pg.id_prenotazione = pr.id_prenotazione) AND (pg.is_confermato IS TRUE))))
  GROUP BY u.id_utente, u.nome, u.cognome, u.email;


ALTER VIEW public.vw_spesa_totale_utente OWNER TO maridapetruccelli;

--
-- TOC entry 250 (class 1259 OID 19046)
-- Name: vw_ticket_viaggio; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_ticket_viaggio AS
 SELECT t.id_ticket_viaggio,
    t.codice_tk,
    t.stato,
    t.totale_pagato
   FROM public.ticketviaggio t;


ALTER VIEW public.vw_ticket_viaggio OWNER TO maridapetruccelli;

--
-- TOC entry 251 (class 1259 OID 19054)
-- Name: vw_voli_con_numero_scali; Type: VIEW; Schema: public; Owner: maridapetruccelli
--

CREATE VIEW public.vw_voli_con_numero_scali AS
 SELECT v.id_volo,
    v.data_ora_partenza_prevista,
    v.data_ora_arrivo_previsto,
    v.stato,
    count(s.id_scalo) AS numero_scali
   FROM (public.volo v
     LEFT JOIN public.scalo s ON ((v.id_volo = s.id_volo)))
  GROUP BY v.id_volo, v.data_ora_partenza_prevista, v.data_ora_arrivo_previsto, v.stato;


ALTER VIEW public.vw_voli_con_numero_scali OWNER TO maridapetruccelli;

--
-- TOC entry 3724 (class 2604 OID 18521)
-- Name: accessorio id_accessorio; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.accessorio ALTER COLUMN id_accessorio SET DEFAULT nextval('public.accessorio_id_accessorio_seq'::regclass);


--
-- TOC entry 3735 (class 2604 OID 18763)
-- Name: biglietto id_biglietto; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto ALTER COLUMN id_biglietto SET DEFAULT nextval('public.biglietto_id_biglietto_seq'::regclass);


--
-- TOC entry 3728 (class 2604 OID 18605)
-- Name: classeprezzo id_classe_prezzo; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.classeprezzo ALTER COLUMN id_classe_prezzo SET DEFAULT nextval('public.classeprezzo_id_classe_prezzo_seq'::regclass);


--
-- TOC entry 3721 (class 2604 OID 18505)
-- Name: pagamento id_pagamento; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.pagamento ALTER COLUMN id_pagamento SET DEFAULT nextval('public.pagamento_id_pagamento_seq'::regclass);


--
-- TOC entry 3737 (class 2604 OID 18796)
-- Name: pagamentoaccessorio id_pagamento_accessorio; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.pagamentoaccessorio ALTER COLUMN id_pagamento_accessorio SET DEFAULT nextval('public.pagamentoaccessorio_id_pagamento_accessorio_seq'::regclass);


--
-- TOC entry 3715 (class 2604 OID 18421)
-- Name: passeggero id_passeggero; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.passeggero ALTER COLUMN id_passeggero SET DEFAULT nextval('public.passeggero_id_passeggero_seq'::regclass);


--
-- TOC entry 3733 (class 2604 OID 18737)
-- Name: posto id_posto; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.posto ALTER COLUMN id_posto SET DEFAULT nextval('public.posto_id_posto_seq'::regclass);


--
-- TOC entry 3717 (class 2604 OID 18463)
-- Name: prenotazione id_prenotazione; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.prenotazione ALTER COLUMN id_prenotazione SET DEFAULT nextval('public.prenotazione_id_prenotazione_seq'::regclass);


--
-- TOC entry 3730 (class 2604 OID 18641)
-- Name: scalo id_scalo; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.scalo ALTER COLUMN id_scalo SET DEFAULT nextval('public.scalo_id_scalo_seq'::regclass);


--
-- TOC entry 3727 (class 2604 OID 18579)
-- Name: segmento id_segmento; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmento ALTER COLUMN id_segmento SET DEFAULT nextval('public.segmento_id_segmento_seq'::regclass);


--
-- TOC entry 3740 (class 2604 OID 18846)
-- Name: storicobiglietto id_storico_biglietto; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicobiglietto ALTER COLUMN id_storico_biglietto SET DEFAULT nextval('public.storicobiglietto_id_storico_biglietto_seq'::regclass);


--
-- TOC entry 3719 (class 2604 OID 18480)
-- Name: storicoprenotazione id_storico_prenotazione; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicoprenotazione ALTER COLUMN id_storico_prenotazione SET DEFAULT nextval('public.storicoprenotazione_id_storico_prenotazione_seq'::regclass);


--
-- TOC entry 3731 (class 2604 OID 18703)
-- Name: ticketviaggio id_ticket_viaggio; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.ticketviaggio ALTER COLUMN id_ticket_viaggio SET DEFAULT nextval('public.ticketviaggio_id_ticket_viaggio_seq'::regclass);


--
-- TOC entry 3726 (class 2604 OID 18547)
-- Name: tratta id_tratta; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.tratta ALTER COLUMN id_tratta SET DEFAULT nextval('public.tratta_id_tratta_seq'::regclass);


--
-- TOC entry 3713 (class 2604 OID 18403)
-- Name: utente id_utente; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.utente ALTER COLUMN id_utente SET DEFAULT nextval('public.utente_id_utente_seq'::regclass);


--
-- TOC entry 3739 (class 2604 OID 18829)
-- Name: variazioneprezzo id_variazione; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.variazioneprezzo ALTER COLUMN id_variazione SET DEFAULT nextval('public.variazioneprezzo_id_variazione_seq'::regclass);


--
-- TOC entry 3729 (class 2604 OID 18631)
-- Name: volo id_volo; Type: DEFAULT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.volo ALTER COLUMN id_volo SET DEFAULT nextval('public.volo_id_volo_seq'::regclass);


--
-- TOC entry 4059 (class 0 OID 18518)
-- Dependencies: 221
-- Data for Name: accessorio; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (1, 'Bagaglio da stiva 23kg', 'Bagaglio in stiva fino a 23kg', 45.00, true, 23.00, '158 cm lineari');
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (2, 'Bagaglio extra 32kg', 'Bagaglio in stiva aggiuntivo fino a 32kg', 70.00, true, 32.00, '158 cm lineari');
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (3, 'Bagaglio a mano aggiuntivo', 'Trolley o zaino aggiuntivo da cabina', 25.00, true, 10.00, '55x40x20 cm');
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (4, 'Scelta posto standard', 'Selezione posto Economy standard', 10.00, true, NULL, NULL);
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (5, 'Scelta posto premium', 'Selezione posto Economy Premium con più spazio', 20.00, true, NULL, NULL);
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (6, 'Scelta posto business', 'Selezione posto Business con priorità imbarco', 0.00, true, NULL, NULL);
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (7, 'Imbarco prioritario', 'Accesso prioritario ai controlli e imbarco veloce', 15.00, true, NULL, NULL);
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (8, 'Wi-Fi a bordo', 'Connessione internet durante il volo', 12.50, true, NULL, NULL);
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (9, 'Kit comfort', 'Coperta, cuscino e mascherina per il riposo', 8.00, true, NULL, NULL);
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (10, 'Menu premium', 'Pasto speciale a scelta (gourmet, vegetariano, ecc.)', 18.00, true, NULL, NULL);
INSERT INTO public.accessorio (id_accessorio, nome, descrizione, prezzo, is_disponibile, peso_massimo, dimensioni_massime) VALUES (11, 'Cambio passeggero', 'Modifica del nominativo del passeggero sul biglietto', 30.00, true, NULL, NULL);


--
-- TOC entry 4061 (class 0 OID 18536)
-- Dependencies: 223
-- Data for Name: aereo; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.aereo (matricola, modello, capacita_passeggeri, anno_costruzione) VALUES ('EI-ITA01', 'Airbus A320neo', 180, 2020);
INSERT INTO public.aereo (matricola, modello, capacita_passeggeri, anno_costruzione) VALUES ('EI-ITA02', 'Airbus A330-200', 268, 2017);
INSERT INTO public.aereo (matricola, modello, capacita_passeggeri, anno_costruzione) VALUES ('EI-ITA03', 'Airbus A350-900', 300, 2021);
INSERT INTO public.aereo (matricola, modello, capacita_passeggeri, anno_costruzione) VALUES ('EI-ITA04', 'Embraer E190', 114, 2016);
INSERT INTO public.aereo (matricola, modello, capacita_passeggeri, anno_costruzione) VALUES ('EI-ITA05', 'Airbus A220-300', 149, 2019);


--
-- TOC entry 4060 (class 0 OID 18531)
-- Dependencies: 222
-- Data for Name: aeroporto; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('FCO', 'Leonardo da Vinci - Fiumicino', 'Roma', 'Italia', 'Europe/Rome');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('LIN', 'Milano Linate', 'Milano', 'Italia', 'Europe/Rome');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('MXP', 'Milano Malpensa', 'Milano', 'Italia', 'Europe/Rome');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('JFK', 'John F. Kennedy International', 'New York', 'USA', 'America/New_York');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('LHR', 'London Heathrow', 'Londra', 'Regno Unito', 'Europe/London');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('CDG', 'Charles de Gaulle', 'Parigi', 'Francia', 'Europe/Paris');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('MAD', 'Adolfo Suárez Madrid–Barajas', 'Madrid', 'Spagna', 'Europe/Madrid');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('FRA', 'Frankfurt am Main Airport', 'Francoforte', 'Germania', 'Europe/Berlin');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('HAV', 'José Martí International Airport', 'L Avana', 'Cuba', 'America/Havana');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('RAK', 'Marrakech Menara Airport', 'Marrakech', 'Marocco', 'Africa/Casablanca');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('DXB', 'Dubai International Airport', 'Dubai', 'Emirati Arabi Uniti', 'Asia/Dubai');
INSERT INTO public.aeroporto (codice_iata, nome, "città", stato, fuso_orario) VALUES ('CAI', 'Cairo International Airport', 'Cairo', 'Egitto', 'Africa/Cairo');


--
-- TOC entry 4079 (class 0 OID 18760)
-- Dependencies: 241
-- Data for Name: biglietto; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (1, 'BK00000001', 1, 1, 5, 'Economy', 90.00, 90.00, false, 'Checked In', NULL);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (2, 'BK00000002', 2, 1, 4, 'Economy Premium', 150.00, 150.00, false, 'Checked In', NULL);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (15, 'BK00000015', 10, 2, 7, 'Business', 170.00, 170.00, false, 'Emesso', NULL);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (16, 'BK00000016', 10, 3, 14, 'Business', 210.00, 210.00, false, 'Emesso', NULL);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (10, 'BK00000010', 7, 3, 16, 'Economy Premium', 150.00, 157.50, false, 'Emesso', 1);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (8, 'BK00000008', 6, 3, 15, 'Economy Premium', 150.00, 157.50, false, 'Emesso', NULL);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (5, 'BK00000005', 4, 5, 25, 'Business', 190.00, 199.50, false, 'Cancellato', 3);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (11, 'BK00000011', 7, 10, 22, 'Economy Premium', 120.00, 126.00, false, 'Emesso', 2);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (9, 'BK00000009', 6, 10, 19, 'Business', 250.00, 262.50, false, 'Emesso', 5);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (12, 'BK00000012', 9, 12, 35, 'Economy', 50.00, 52.50, false, 'Checked In', 2);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (13, 'BK00000013', 9, 13, 42, 'Economy', 90.00, 94.50, false, 'Checked In', 3);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (14, 'BK00000014', 4, 14, 43, 'Business', 180.00, 180.00, false, 'Checked In', NULL);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (6, 'BK00000006', 5, 16, 51, 'Economy', 120.00, 120.00, false, 'Emesso', NULL);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (7, 'BK00000007', 5, 18, 57, 'Economy', 90.00, 94.50, false, 'Emesso', 3);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (4, 'BK00000004', 3, 18, 55, 'Economy Premium', 150.00, 157.50, false, 'Emesso', 3);
INSERT INTO public.biglietto (id_biglietto, codice_biglietto, id_ticket_viaggio, id_segmento, id_posto, classe, prezzo_base, prezzo_effettivo, is_modificato, stato, id_variazione) VALUES (3, 'BK00000003', 3, 16, 49, 'Economy Premium', 140.00, 140.00, false, 'Emesso', NULL);


--
-- TOC entry 4067 (class 0 OID 18602)
-- Dependencies: 229
-- Data for Name: classeprezzo; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (1, 1, 'Economy', 120.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (2, 1, 'Economy Premium', 200.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (3, 1, 'Business', 350.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (4, 2, 'Economy', 90.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (5, 2, 'Economy Premium', 160.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (6, 2, 'Business', 300.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (7, 3, 'Economy', 150.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (8, 3, 'Economy Premium', 240.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (9, 3, 'Business', 400.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (10, 5, 'Economy', 100.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (11, 5, 'Economy Premium', 180.00);
INSERT INTO public.classeprezzo (id_classe_prezzo, id_segmento, classe, prezzo) VALUES (12, 5, 'Business', 320.00);


--
-- TOC entry 4051 (class 0 OID 18437)
-- Dependencies: 213
-- Data for Name: fidelizzatovolare; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.fidelizzatovolare (codice_volare, id_passeggero, data_adesione, punti, livello) VALUES ('VOL12345', 1, '2022-03-15', 15000, 'Plus');
INSERT INTO public.fidelizzatovolare (codice_volare, id_passeggero, data_adesione, punti, livello) VALUES ('VOL67890', 3, '2023-06-01', 5000, 'Smart');
INSERT INTO public.fidelizzatovolare (codice_volare, id_passeggero, data_adesione, punti, livello) VALUES ('VOL54321', 5, '2020-11-20', 32000, 'Premium');
INSERT INTO public.fidelizzatovolare (codice_volare, id_passeggero, data_adesione, punti, livello) VALUES ('VOL11223', 8, '2021-09-10', 48000, 'Executive');


--
-- TOC entry 4057 (class 0 OID 18502)
-- Dependencies: 219
-- Data for Name: pagamento; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.pagamento (id_pagamento, id_prenotazione, data_pagamento, metodo_pagamento, importo, is_confermato) VALUES (1, 1, '2025-09-02', 'Carta di Credito', 240.00, true);
INSERT INTO public.pagamento (id_pagamento, id_prenotazione, data_pagamento, metodo_pagamento, importo, is_confermato) VALUES (4, 3, '2025-09-05', 'PayPal', 703.50, true);
INSERT INTO public.pagamento (id_pagamento, id_prenotazione, data_pagamento, metodo_pagamento, importo, is_confermato) VALUES (5, 4, '2025-09-06', 'Carta di Credito', 0.00, false);
INSERT INTO public.pagamento (id_pagamento, id_prenotazione, data_pagamento, metodo_pagamento, importo, is_confermato) VALUES (6, 5, '2025-09-07', 'Voucher', 147.00, true);
INSERT INTO public.pagamento (id_pagamento, id_prenotazione, data_pagamento, metodo_pagamento, importo, is_confermato) VALUES (7, 6, '2025-09-09', 'Carta di Credito', 380.00, true);
INSERT INTO public.pagamento (id_pagamento, id_prenotazione, data_pagamento, metodo_pagamento, importo, is_confermato) VALUES (2, 2, '2025-09-03', 'Bonifico', 0.00, false);
INSERT INTO public.pagamento (id_pagamento, id_prenotazione, data_pagamento, metodo_pagamento, importo, is_confermato) VALUES (3, 2, '2025-09-04', 'Bonifico', 891.50, true);


--
-- TOC entry 4081 (class 0 OID 18793)
-- Dependencies: 243
-- Data for Name: pagamentoaccessorio; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.pagamentoaccessorio (id_pagamento_accessorio, id_biglietto, id_accessorio, "quantità", data_pagamento, prezzo_pagato, metodo_pagamento) VALUES (4, 4, 3, 1, '2025-09-12', 20.00, 'Voucher');


--
-- TOC entry 4050 (class 0 OID 18418)
-- Dependencies: 212
-- Data for Name: passeggero; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (1, 'Marco', 'Rossi', '1990-03-15', 'Passaporto', 'YA1234567', '2030-05-15');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (2, 'Luca', 'Rossi', '2012-07-20', 'Carta Identità', 'CI9988776', '2027-07-20');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (3, 'Laura', 'Bianchi', '1985-09-02', 'Carta Identità', 'CIBNCH85L02H501T', '2030-09-02');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (4, 'Sara', 'Neri', '1995-11-11', 'Passaporto', 'XN4455667', '2029-11-11');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (5, 'Alessandro', 'Conti', '1980-01-25', 'Passaporto', 'XP1239874', '2031-01-25');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (6, 'Chiara', 'Russo', '2001-06-18', 'Carta Identità', 'CIRSS01H58F205Z', '2029-06-18');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (7, 'Michael', 'Johnson', '1992-12-09', 'Passaporto', 'US55667788', '2032-12-09');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (8, 'Sophie', 'Dupont', '1988-04-04', 'Passaporto', 'FR11223344', '2031-04-04');
INSERT INTO public.passeggero (id_passeggero, nome, cognome, data_nascita, tipo_documento, numero_documento, scadenza_documento) VALUES (9, 'Giovanni', 'Bianchi', '1955-10-30', 'Carta Identità', 'CIBNCH55R30H501A', '2026-10-30');


--
-- TOC entry 4077 (class 0 OID 18734)
-- Dependencies: 239
-- Data for Name: posto; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (1, 1, '1A', 'Business', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (2, 1, '1B', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (3, 1, '2A', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (6, 1, '10B', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (8, 2, '1B', 'Business', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (9, 2, '2A', 'Economy Premium', 'Bloccato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (10, 2, '2B', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (11, 2, '11A', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (12, 2, '11B', 'Economy', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (13, 3, '1A', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (17, 3, '20A', 'Economy', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (18, 3, '20B', 'Economy', 'Bloccato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (4, 1, '2B', 'Economy Premium', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (26, 5, '1B', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (27, 5, '2A', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (28, 5, '2B', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (29, 5, '15A', 'Economy', 'Bloccato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (30, 5, '15B', 'Economy', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (5, 1, '10A', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (7, 2, '1A', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (14, 3, '1B', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (43, 14, '1A', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (49, 16, 'A1', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (51, 16, 'A3', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (20, 10, '1B', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (21, 10, '2A', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (23, 10, '21A', 'Economy', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (24, 10, '21B', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (31, 12, '1A', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (32, 12, '1B', 'Business', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (33, 12, '2A', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (34, 12, '2B', 'Economy Premium', 'Bloccato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (36, 12, '16B', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (37, 13, '1A', 'Business', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (38, 13, '1B', 'Business', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (39, 13, '2A', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (40, 13, '2B', 'Economy Premium', 'Bloccato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (41, 13, '12A', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (44, 14, '1B', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (45, 14, '2A', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (46, 14, '2B', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (47, 14, '13A', 'Economy', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (48, 14, '13B', 'Economy', 'Bloccato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (50, 16, 'A2', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (52, 16, 'A4', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (53, 16, 'A5', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (54, 16, 'A6', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (56, 18, 'A2', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (58, 18, 'A4', 'Economy Premium', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (59, 18, 'A5', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (55, 18, 'A1', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (60, 7, 'A1', 'Business', 'Libero');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (25, 5, '1A', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (57, 18, 'A3', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (15, 3, '2A', 'Economy Premium', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (19, 10, '1A', 'Business', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (16, 3, '2B', 'Economy Premium', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (22, 10, '2B', 'Economy Premium', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (35, 12, '16A', 'Economy', 'Occupato');
INSERT INTO public.posto (id_posto, id_segmento, numero_posto, classe, stato) VALUES (42, 13, '12B', 'Economy', 'Occupato');


--
-- TOC entry 4053 (class 0 OID 18460)
-- Dependencies: 215
-- Data for Name: prenotazione; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.prenotazione (id_prenotazione, codice_prenotazione, id_utente, data_prenotazione, stato, importo_totale) VALUES (2, 'PNR002', 2, '2025-09-02', 'Confermata', 891.50);
INSERT INTO public.prenotazione (id_prenotazione, codice_prenotazione, id_utente, data_prenotazione, stato, importo_totale) VALUES (1, 'PNR001', 1, '2025-09-01', 'Confermata', 240.00);
INSERT INTO public.prenotazione (id_prenotazione, codice_prenotazione, id_utente, data_prenotazione, stato, importo_totale) VALUES (3, 'PNR003', 3, '2025-09-03', 'Confermata', 703.50);
INSERT INTO public.prenotazione (id_prenotazione, codice_prenotazione, id_utente, data_prenotazione, stato, importo_totale) VALUES (4, 'PNR004', 1, '2025-09-05', 'Attiva', 0.00);
INSERT INTO public.prenotazione (id_prenotazione, codice_prenotazione, id_utente, data_prenotazione, stato, importo_totale) VALUES (5, 'PNR005', 4, '2025-09-06', 'Confermata', 147.00);
INSERT INTO public.prenotazione (id_prenotazione, codice_prenotazione, id_utente, data_prenotazione, stato, importo_totale) VALUES (6, 'PNR006', 2, '2025-09-08', 'Confermata', 380.00);


--
-- TOC entry 4073 (class 0 OID 18675)
-- Dependencies: 235
-- Data for Name: prenotazionevolo; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.prenotazionevolo (id_prenotazione, id_volo) VALUES (1, 1);
INSERT INTO public.prenotazionevolo (id_prenotazione, id_volo) VALUES (2, 9);
INSERT INTO public.prenotazionevolo (id_prenotazione, id_volo) VALUES (2, 5);
INSERT INTO public.prenotazionevolo (id_prenotazione, id_volo) VALUES (3, 3);
INSERT INTO public.prenotazionevolo (id_prenotazione, id_volo) VALUES (4, 4);
INSERT INTO public.prenotazionevolo (id_prenotazione, id_volo) VALUES (5, 6);
INSERT INTO public.prenotazionevolo (id_prenotazione, id_volo) VALUES (6, 7);


--
-- TOC entry 4071 (class 0 OID 18638)
-- Dependencies: 233
-- Data for Name: scalo; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.scalo (id_scalo, id_volo, codice_iata, ordine, tempo_attesa) VALUES (1, 3, 'FCO', 1, '01:30:00');
INSERT INTO public.scalo (id_scalo, id_volo, codice_iata, ordine, tempo_attesa) VALUES (2, 6, 'LHR', 1, '02:00:00');
INSERT INTO public.scalo (id_scalo, id_volo, codice_iata, ordine, tempo_attesa) VALUES (3, 6, 'JFK', 2, '02:30:00');
INSERT INTO public.scalo (id_scalo, id_volo, codice_iata, ordine, tempo_attesa) VALUES (4, 9, 'FCO', 1, '01:30:00');
INSERT INTO public.scalo (id_scalo, id_volo, codice_iata, ordine, tempo_attesa) VALUES (5, 10, 'FCO', 1, '02:00:00');


--
-- TOC entry 4065 (class 0 OID 18576)
-- Dependencies: 227
-- Data for Name: segmento; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (5, 7, 'EI-ITA04', 'AZ732', '2025-05-22 07:10:00', '2025-05-22 09:40:00', NULL, NULL, 'M03', 'N01', 'Cancellato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (6, 8, 'EI-ITA04', 'AZ733', '2025-09-18 18:00:00', '2025-09-18 19:02:16', NULL, NULL, 'P07', 'Q02', 'In partenza');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (12, 10, 'EI-ITA01', 'AZ700', '2025-09-18 15:00:00', '2025-09-18 16:15:52', '2025-09-18 15:05:52', '2025-09-18 16:15:52', 'G05', 'B12', 'Atterrato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (13, 11, 'EI-ITA03', 'AZ701', '2025-09-18 17:00:00', '2025-09-18 18:26:53', '2025-09-18 17:26:53', NULL, 'C10', 'F20', 'In Volo');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (14, 12, 'EI-ITA04', 'AZ702', '2025-09-18 18:47:00', '2025-09-18 20:47:19', NULL, NULL, 'D02', 'H07', 'In partenza');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (7, 9, 'EI-ITA05', 'AZ920', '2025-09-18 18:06:00', '2025-09-18 19:21:58', NULL, NULL, 'L01', 'Z03', 'In partenza');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (16, 14, 'EI-ITA04', 'AZ892', '2025-09-18 18:06:40', '2025-09-18 18:31:40', '2025-09-18 17:32:48', NULL, 'C03', 'D14', 'In Volo');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (17, 15, 'EI-ITA04', 'AZ894', '2025-09-20 18:22:38', '2025-09-20 19:42:38', NULL, NULL, 'E22', 'F05', 'Programmato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (4, 4, 'EI-ITA03', 'AZ621', '2025-07-15 19:00:00', '2025-07-16 07:20:00', '2025-07-15 19:02:00', '2025-07-16 07:18:00', 'E03', 'H06', 'Atterrato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (8, 5, 'EI-ITA01', 'AZ450', '2025-05-05 08:30:00', '2025-05-05 11:10:00', '2025-05-05 08:55:00', '2025-05-05 11:35:00', 'A02', 'K09', 'Atterrato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (19, 17, 'EI-ITA05', 'AZ893', '2025-09-17 13:00:00', '2025-09-17 15:10:00', '2025-09-17 13:20:00', '2025-09-17 15:20:00', 'D10', 'C06', 'Atterrato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (15, 13, 'EI-ITA03', 'AZ890', '2025-09-17 17:45:00', '2025-09-17 20:00:00', '2025-09-17 17:55:00', '2025-09-17 20:25:00', 'A12', 'B07', 'Programmato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (11, 9, 'EI-ITA05', 'AZ922', '2025-09-18 16:32:30', '2025-09-18 18:22:30', '2025-09-18 16:32:30', NULL, 'L03', 'Z01', 'In Volo');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (1, 1, 'EI-ITA01', 'AZ610', '2025-09-18 18:03:00', '2025-09-18 19:18:59', NULL, NULL, 'G12', 'B04', 'In partenza');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (18, 16, 'EI-ITA03', 'AZ891', '2025-09-18 11:00:00', '2025-09-18 13:00:00', '2025-09-18 11:00:00', '2025-09-18 13:10:00', 'B08', 'A15', 'Atterrato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (9, 6, 'EI-ITA01', 'AZ451', '2025-05-12 14:20:00', '2025-05-12 16:55:00', '2025-05-12 14:20:00', '2025-05-12 17:15:00', 'B07', 'L02', 'Atterrato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (3, 3, 'EI-ITA03', 'AZ620', '2025-09-18 20:30:00', '2025-09-18 22:10:44', '2025-09-18 20:30:44', NULL, 'D01', 'T04', 'Programmato');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (2, 2, 'EI-ITA01', 'AZ611', '2025-09-18 17:00:00', '2025-09-18 19:11:05', '2025-09-18 17:21:05', NULL, 'C05', 'F08', 'In Ritardo');
INSERT INTO public.segmento (id_segmento, id_tratta, matricola_aereo, codice_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, gate_partenza, gate_arrivo, stato) VALUES (10, 5, 'EI-ITA01', 'AZ452', '2025-09-18 11:00:00', '2025-09-18 14:15:44', '2025-09-18 11:40:44', '2025-09-18 14:15:44', 'A03', 'K10', 'Atterrato');


--
-- TOC entry 4072 (class 0 OID 18657)
-- Dependencies: 234
-- Data for Name: segmentoinvolo; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (1, 1, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (3, 2, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (10, 3, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (3, 3, 2);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (9, 4, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (5, 5, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (12, 6, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (13, 6, 2);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (14, 6, 3);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (2, 7, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (3, 7, 2);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (7, 8, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (18, 9, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (16, 9, 2);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (19, 10, 1);
INSERT INTO public.segmentoinvolo (id_segmento, id_volo, ordine_segmento) VALUES (15, 10, 2);


--
-- TOC entry 4085 (class 0 OID 18843)
-- Dependencies: 247
-- Data for Name: storicobiglietto; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.storicobiglietto (id_storico_biglietto, id_biglietto, id_vecchio_passeggero, id_nuovo_passeggero, data_modifica, motivo) VALUES (3, 4, 4, 7, '2025-09-13', 'Richiesta del cliente: trasferimento biglietto a passeggero 7');


--
-- TOC entry 4055 (class 0 OID 18477)
-- Dependencies: 217
-- Data for Name: storicoprenotazione; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.storicoprenotazione (id_storico_prenotazione, id_prenotazione, data_modifica, note) VALUES (1, 1, '2025-09-02', 'Prenotazione confermata dall’utente');
INSERT INTO public.storicoprenotazione (id_storico_prenotazione, id_prenotazione, data_modifica, note) VALUES (2, 2, '2025-09-03', 'Aggiunto secondo volo alla prenotazione');
INSERT INTO public.storicoprenotazione (id_storico_prenotazione, id_prenotazione, data_modifica, note) VALUES (3, 2, '2025-09-04', 'Pagamento completato, prenotazione confermata');
INSERT INTO public.storicoprenotazione (id_storico_prenotazione, id_prenotazione, data_modifica, note) VALUES (4, 3, '2025-09-05', 'Cambio di stato: da Attiva a Confermata');
INSERT INTO public.storicoprenotazione (id_storico_prenotazione, id_prenotazione, data_modifica, note) VALUES (5, 4, '2025-09-06', 'Prenotazione annullata su richiesta cliente');
INSERT INTO public.storicoprenotazione (id_storico_prenotazione, id_prenotazione, data_modifica, note) VALUES (6, 5, '2025-09-07', 'Modificato volo assegnato');
INSERT INTO public.storicoprenotazione (id_storico_prenotazione, id_prenotazione, data_modifica, note) VALUES (7, 6, '2025-09-09', 'Prenotazione confermata automaticamente dopo pagamento');


--
-- TOC entry 4075 (class 0 OID 18700)
-- Dependencies: 237
-- Data for Name: ticketviaggio; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (3, 'TK0003', 2, 2, 9, '2025-09-02', 'Attivo', 297.50);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (8, 'TK0008', 4, 1, 4, '2025-09-05', 'Annullato', NULL);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (1, 'TK0001', 1, 1, 1, '2025-09-01', 'Attivo', 90.00);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (2, 'TK0002', 1, 3, 1, '2025-09-01', 'Attivo', 150.00);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (10, 'TK0010', 6, 9, 7, '2025-09-08', 'Attivo', 380.00);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (7, 'TK0007', 3, 4, 3, '2025-09-03', 'Terminato', 283.50);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (6, 'TK0006', 3, 6, 3, '2025-09-03', 'Terminato', 420.00);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (9, 'TK0009', 5, 8, 6, '2025-09-06', 'Attivo', 147.00);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (4, 'TK0004', 2, 2, 5, '2025-09-02', 'Attivo', 379.50);
INSERT INTO public.ticketviaggio (id_ticket_viaggio, codice_tk, id_prenotazione, id_passeggero, id_volo, data_emissione, stato, totale_pagato) VALUES (5, 'TK0005', 2, 5, 9, '2025-09-02', 'Attivo', 214.50);


--
-- TOC entry 4063 (class 0 OID 18544)
-- Dependencies: 225
-- Data for Name: tratta; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (1, 'AZRMPAR', 'FCO', 'CDG', '02:10:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (2, 'AZPARRM', 'CDG', 'FCO', '02:15:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (3, 'AZRMNYC', 'FCO', 'JFK', '08:30:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (4, 'AZNYCRM', 'JFK', 'FCO', '08:20:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (5, 'AZLONRM', 'LHR', 'FCO', '02:35:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (6, 'AZMXPMAD', 'MXP', 'MAD', '02:30:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (7, 'AZMADMXP', 'MAD', 'MXP', '02:25:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (8, 'AZLINFRA', 'LIN', 'FRA', '01:30:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (9, 'AZFRALIN', 'FRA', 'LIN', '01:25:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (10, 'AZRMLON', 'FCO', 'LHR', '02:40:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (11, 'AZLONNYC', 'LHR', 'JFK', '08:00:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (12, 'AZNYCHAV', 'JFK', 'HAV', '03:30:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (13, 'FCO-RAK', 'FCO', 'RAK', '04:00:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (14, 'FCO-DXB', 'FCO', 'DXB', '06:30:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (15, 'DXB-CAI', 'DXB', 'CAI', '04:00:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (16, 'RAK-FCO', 'RAK', 'FCO', '03:45:00');
INSERT INTO public.tratta (id_tratta, codice_rotta, codice_iata_partenza, codice_iata_arrivo, durata_media) VALUES (17, 'DXB-FCO', 'DXB', 'FCO', '06:30:00');


--
-- TOC entry 4048 (class 0 OID 18400)
-- Dependencies: 210
-- Data for Name: utente; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.utente (id_utente, nome, cognome, email, telefono, is_registrato, password, data_registrazione) VALUES (1, 'Marco', 'Rossi', 'marco.rossi@email.it', '+393331234567', true, 'pass123', '2024-05-10');
INSERT INTO public.utente (id_utente, nome, cognome, email, telefono, is_registrato, password, data_registrazione) VALUES (2, 'Laura', 'Bianchi', 'laura.bianchi@email.it', '+393331112233', false, NULL, NULL);
INSERT INTO public.utente (id_utente, nome, cognome, email, telefono, is_registrato, password, data_registrazione) VALUES (3, 'Giulia', 'Verdi', 'giulia.verdi@email.it', '+393334445566', true, 'securepwd', '2023-11-02');
INSERT INTO public.utente (id_utente, nome, cognome, email, telefono, is_registrato, password, data_registrazione) VALUES (4, 'John', 'Smith', 'john.smith@email.com', '+15551234567', false, NULL, NULL);


--
-- TOC entry 4083 (class 0 OID 18826)
-- Dependencies: 245
-- Data for Name: variazioneprezzo; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.variazioneprezzo (id_variazione, tipo_variazione, descrizione, percentuale, importo_variazione, data_inizio_variazione, data_fine_variazione) VALUES (1, 'Promozione', 'Sconto del 20% per acquisti anticipati', -20.00, NULL, '2025-09-01', '2025-09-15');
INSERT INTO public.variazioneprezzo (id_variazione, tipo_variazione, descrizione, percentuale, importo_variazione, data_inizio_variazione, data_fine_variazione) VALUES (2, 'Stagionale', 'Aumento prezzi periodo natalizio', 15.00, NULL, '2025-12-15', '2026-01-10');
INSERT INTO public.variazioneprezzo (id_variazione, tipo_variazione, descrizione, percentuale, importo_variazione, data_inizio_variazione, data_fine_variazione) VALUES (3, 'Operativa', 'Ricalcolo prezzo per cambio orario volo', 5.00, NULL, '2025-09-10', '2025-09-30');
INSERT INTO public.variazioneprezzo (id_variazione, tipo_variazione, descrizione, percentuale, importo_variazione, data_inizio_variazione, data_fine_variazione) VALUES (4, 'Supplemento', 'Bagaglio extra incluso nel biglietto', 10.00, NULL, '2025-09-05', '2025-09-20');
INSERT INTO public.variazioneprezzo (id_variazione, tipo_variazione, descrizione, percentuale, importo_variazione, data_inizio_variazione, data_fine_variazione) VALUES (5, 'Rimborso_Parziale', 'Rimborso parziale per ritardo superiore a 3 ore', -30.00, NULL, '2025-09-01', '2025-12-31');
INSERT INTO public.variazioneprezzo (id_variazione, tipo_variazione, descrizione, percentuale, importo_variazione, data_inizio_variazione, data_fine_variazione) VALUES (6, 'Altro', 'Sconto speciale partnership aziendale', -25.00, NULL, '2025-09-01', '2025-11-30');


--
-- TOC entry 4069 (class 0 OID 18628)
-- Dependencies: 231
-- Data for Name: volo; Type: TABLE DATA; Schema: public; Owner: maridapetruccelli
--

INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (8, '2025-09-18 18:06:00', '2025-09-18 19:21:58', '01:15:58', NULL, NULL, NULL, 'In Partenza');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (10, '2025-09-17 13:00:00', '2025-09-17 20:00:00', '07:00:00', '2025-09-17 13:20:00', '2025-09-17 20:25:00', 25, 'Arrivato');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (1, '2025-09-18 18:03:00', '2025-09-18 19:18:59', '01:15:59', NULL, NULL, NULL, 'In Partenza');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (9, '2025-09-18 11:00:00', '2025-09-18 18:31:40', '07:31:40', '2025-09-18 11:00:00', NULL, NULL, 'In Volo');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (4, '2025-05-12 14:20:00', '2025-05-12 16:55:00', '02:35:00', '2025-05-12 14:20:00', '2025-05-12 17:15:00', 20, 'Arrivato');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (2, '2025-09-18 20:30:00', '2025-09-18 22:10:44', '01:40:44', '2025-09-18 20:30:44', NULL, NULL, 'Programmato');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (7, '2025-09-18 17:00:00', '2025-09-18 22:10:44', '05:10:44', '2025-09-18 17:21:05', NULL, NULL, 'Programmato');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (3, '2025-09-18 11:00:00', '2025-09-18 22:10:44', '11:10:44', '2025-09-18 11:40:44', NULL, NULL, 'Programmato');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (5, '2025-05-22 07:10:00', '2025-05-22 09:40:00', '02:30:00', NULL, NULL, NULL, 'Cancellato');
INSERT INTO public.volo (id_volo, data_ora_partenza_prevista, data_ora_arrivo_previsto, durata, data_ora_partenza_effettiva, data_ora_arrivo_effettivo, ritardo_totale, stato) VALUES (6, '2025-09-18 15:00:00', '2025-09-18 20:47:19', '05:47:19', '2025-09-18 15:05:52', NULL, NULL, 'In Partenza');


--
-- TOC entry 4110 (class 0 OID 0)
-- Dependencies: 220
-- Name: accessorio_id_accessorio_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.accessorio_id_accessorio_seq', 11, true);


--
-- TOC entry 4111 (class 0 OID 0)
-- Dependencies: 240
-- Name: biglietto_id_biglietto_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.biglietto_id_biglietto_seq', 1, true);


--
-- TOC entry 4112 (class 0 OID 0)
-- Dependencies: 248
-- Name: bk_code_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.bk_code_seq', 1, false);


--
-- TOC entry 4113 (class 0 OID 0)
-- Dependencies: 228
-- Name: classeprezzo_id_classe_prezzo_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.classeprezzo_id_classe_prezzo_seq', 1, false);


--
-- TOC entry 4114 (class 0 OID 0)
-- Dependencies: 218
-- Name: pagamento_id_pagamento_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.pagamento_id_pagamento_seq', 1, false);


--
-- TOC entry 4115 (class 0 OID 0)
-- Dependencies: 242
-- Name: pagamentoaccessorio_id_pagamento_accessorio_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.pagamentoaccessorio_id_pagamento_accessorio_seq', 1, false);


--
-- TOC entry 4116 (class 0 OID 0)
-- Dependencies: 211
-- Name: passeggero_id_passeggero_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.passeggero_id_passeggero_seq', 9, true);


--
-- TOC entry 4117 (class 0 OID 0)
-- Dependencies: 238
-- Name: posto_id_posto_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.posto_id_posto_seq', 48, true);


--
-- TOC entry 4118 (class 0 OID 0)
-- Dependencies: 214
-- Name: prenotazione_id_prenotazione_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.prenotazione_id_prenotazione_seq', 1, false);


--
-- TOC entry 4119 (class 0 OID 0)
-- Dependencies: 232
-- Name: scalo_id_scalo_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.scalo_id_scalo_seq', 1, false);


--
-- TOC entry 4120 (class 0 OID 0)
-- Dependencies: 226
-- Name: segmento_id_segmento_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.segmento_id_segmento_seq', 14, true);


--
-- TOC entry 4121 (class 0 OID 0)
-- Dependencies: 246
-- Name: storicobiglietto_id_storico_biglietto_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.storicobiglietto_id_storico_biglietto_seq', 1, false);


--
-- TOC entry 4122 (class 0 OID 0)
-- Dependencies: 216
-- Name: storicoprenotazione_id_storico_prenotazione_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.storicoprenotazione_id_storico_prenotazione_seq', 1, false);


--
-- TOC entry 4123 (class 0 OID 0)
-- Dependencies: 236
-- Name: ticketviaggio_id_ticket_viaggio_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.ticketviaggio_id_ticket_viaggio_seq', 1, false);


--
-- TOC entry 4124 (class 0 OID 0)
-- Dependencies: 224
-- Name: tratta_id_tratta_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.tratta_id_tratta_seq', 12, true);


--
-- TOC entry 4125 (class 0 OID 0)
-- Dependencies: 209
-- Name: utente_id_utente_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.utente_id_utente_seq', 4, true);


--
-- TOC entry 4126 (class 0 OID 0)
-- Dependencies: 244
-- Name: variazioneprezzo_id_variazione_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.variazioneprezzo_id_variazione_seq', 1, false);


--
-- TOC entry 4127 (class 0 OID 0)
-- Dependencies: 230
-- Name: volo_id_volo_seq; Type: SEQUENCE SET; Schema: public; Owner: maridapetruccelli
--

SELECT pg_catalog.setval('public.volo_id_volo_seq', 10, true);


--
-- TOC entry 3795 (class 2606 OID 18530)
-- Name: accessorio accessorio_nome_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.accessorio
    ADD CONSTRAINT accessorio_nome_key UNIQUE (nome);


--
-- TOC entry 3797 (class 2606 OID 18528)
-- Name: accessorio accessorio_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.accessorio
    ADD CONSTRAINT accessorio_pkey PRIMARY KEY (id_accessorio);


--
-- TOC entry 3801 (class 2606 OID 18542)
-- Name: aereo aereo_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.aereo
    ADD CONSTRAINT aereo_pkey PRIMARY KEY (matricola);


--
-- TOC entry 3799 (class 2606 OID 18535)
-- Name: aeroporto aeroporto_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.aeroporto
    ADD CONSTRAINT aeroporto_pkey PRIMARY KEY (codice_iata);


--
-- TOC entry 3842 (class 2606 OID 18770)
-- Name: biglietto biglietto_codice_biglietto_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT biglietto_codice_biglietto_key UNIQUE (codice_biglietto);


--
-- TOC entry 3844 (class 2606 OID 18768)
-- Name: biglietto biglietto_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT biglietto_pkey PRIMARY KEY (id_biglietto);


--
-- TOC entry 3812 (class 2606 OID 18608)
-- Name: classeprezzo classeprezzo_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.classeprezzo
    ADD CONSTRAINT classeprezzo_pkey PRIMARY KEY (id_classe_prezzo);


--
-- TOC entry 3781 (class 2606 OID 18446)
-- Name: fidelizzatovolare fidelizzatovolare_id_passeggero_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.fidelizzatovolare
    ADD CONSTRAINT fidelizzatovolare_id_passeggero_key UNIQUE (id_passeggero);


--
-- TOC entry 3783 (class 2606 OID 18444)
-- Name: fidelizzatovolare fidelizzatovolare_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.fidelizzatovolare
    ADD CONSTRAINT fidelizzatovolare_pkey PRIMARY KEY (codice_volare);


--
-- TOC entry 3793 (class 2606 OID 18511)
-- Name: pagamento pagamento_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.pagamento
    ADD CONSTRAINT pagamento_pkey PRIMARY KEY (id_pagamento);


--
-- TOC entry 3852 (class 2606 OID 18801)
-- Name: pagamentoaccessorio pagamentoaccessorio_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.pagamentoaccessorio
    ADD CONSTRAINT pagamentoaccessorio_pkey PRIMARY KEY (id_pagamento_accessorio);


--
-- TOC entry 3777 (class 2606 OID 18427)
-- Name: passeggero passeggero_numero_documento_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.passeggero
    ADD CONSTRAINT passeggero_numero_documento_key UNIQUE (numero_documento);


--
-- TOC entry 3779 (class 2606 OID 18425)
-- Name: passeggero passeggero_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.passeggero
    ADD CONSTRAINT passeggero_pkey PRIMARY KEY (id_passeggero);


--
-- TOC entry 3838 (class 2606 OID 18740)
-- Name: posto posto_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.posto
    ADD CONSTRAINT posto_pkey PRIMARY KEY (id_posto);


--
-- TOC entry 3786 (class 2606 OID 18470)
-- Name: prenotazione prenotazione_codice_prenotazione_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT prenotazione_codice_prenotazione_key UNIQUE (codice_prenotazione);


--
-- TOC entry 3788 (class 2606 OID 18468)
-- Name: prenotazione prenotazione_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT prenotazione_pkey PRIMARY KEY (id_prenotazione);


--
-- TOC entry 3826 (class 2606 OID 18679)
-- Name: prenotazionevolo prenotazionevolo_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.prenotazionevolo
    ADD CONSTRAINT prenotazionevolo_pkey PRIMARY KEY (id_prenotazione, id_volo);


--
-- TOC entry 3817 (class 2606 OID 18644)
-- Name: scalo scalo_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.scalo
    ADD CONSTRAINT scalo_pkey PRIMARY KEY (id_scalo);


--
-- TOC entry 3810 (class 2606 OID 18583)
-- Name: segmento segmento_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmento
    ADD CONSTRAINT segmento_pkey PRIMARY KEY (id_segmento);


--
-- TOC entry 3822 (class 2606 OID 18662)
-- Name: segmentoinvolo segmentoinvolo_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmentoinvolo
    ADD CONSTRAINT segmentoinvolo_pkey PRIMARY KEY (id_segmento, id_volo);


--
-- TOC entry 3856 (class 2606 OID 18853)
-- Name: storicobiglietto storicobiglietto_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicobiglietto
    ADD CONSTRAINT storicobiglietto_pkey PRIMARY KEY (id_storico_biglietto);


--
-- TOC entry 3790 (class 2606 OID 18485)
-- Name: storicoprenotazione storicoprenotazione_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicoprenotazione
    ADD CONSTRAINT storicoprenotazione_pkey PRIMARY KEY (id_storico_prenotazione);


--
-- TOC entry 3830 (class 2606 OID 18710)
-- Name: ticketviaggio ticketviaggio_codice_tk_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.ticketviaggio
    ADD CONSTRAINT ticketviaggio_codice_tk_key UNIQUE (codice_tk);


--
-- TOC entry 3832 (class 2606 OID 18708)
-- Name: ticketviaggio ticketviaggio_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.ticketviaggio
    ADD CONSTRAINT ticketviaggio_pkey PRIMARY KEY (id_ticket_viaggio);


--
-- TOC entry 3805 (class 2606 OID 18553)
-- Name: tratta tratta_codice_rotta_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.tratta
    ADD CONSTRAINT tratta_codice_rotta_key UNIQUE (codice_rotta);


--
-- TOC entry 3807 (class 2606 OID 18551)
-- Name: tratta tratta_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.tratta
    ADD CONSTRAINT tratta_pkey PRIMARY KEY (id_tratta);


--
-- TOC entry 3848 (class 2606 OID 18789)
-- Name: biglietto uq_seg_posto_ticket; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT uq_seg_posto_ticket UNIQUE (id_segmento, id_posto, id_ticket_viaggio);


--
-- TOC entry 3840 (class 2606 OID 18742)
-- Name: posto uq_segmento_numero; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.posto
    ADD CONSTRAINT uq_segmento_numero UNIQUE (id_segmento, numero_posto);


--
-- TOC entry 3824 (class 2606 OID 18664)
-- Name: segmentoinvolo uq_siv_ordine; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmentoinvolo
    ADD CONSTRAINT uq_siv_ordine UNIQUE (id_volo, ordine_segmento);


--
-- TOC entry 3850 (class 2606 OID 18772)
-- Name: biglietto uq_ticket_segmento; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT uq_ticket_segmento UNIQUE (id_ticket_viaggio, id_segmento);


--
-- TOC entry 3834 (class 2606 OID 18791)
-- Name: ticketviaggio uq_ticket_triplet; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.ticketviaggio
    ADD CONSTRAINT uq_ticket_triplet UNIQUE (id_prenotazione, id_passeggero, id_volo);


--
-- TOC entry 3819 (class 2606 OID 18646)
-- Name: scalo uq_volo_ordine; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.scalo
    ADD CONSTRAINT uq_volo_ordine UNIQUE (id_volo, ordine);


--
-- TOC entry 3773 (class 2606 OID 18409)
-- Name: utente utente_email_key; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.utente
    ADD CONSTRAINT utente_email_key UNIQUE (email);


--
-- TOC entry 3775 (class 2606 OID 18407)
-- Name: utente utente_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.utente
    ADD CONSTRAINT utente_pkey PRIMARY KEY (id_utente);


--
-- TOC entry 3854 (class 2606 OID 18836)
-- Name: variazioneprezzo variazioneprezzo_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.variazioneprezzo
    ADD CONSTRAINT variazioneprezzo_pkey PRIMARY KEY (id_variazione);


--
-- TOC entry 3815 (class 2606 OID 18636)
-- Name: volo volo_pkey; Type: CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.volo
    ADD CONSTRAINT volo_pkey PRIMARY KEY (id_volo);


--
-- TOC entry 3845 (class 1259 OID 18871)
-- Name: idx_biglietto_id_ticket_viaggio; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_biglietto_id_ticket_viaggio ON public.biglietto USING btree (id_ticket_viaggio);


--
-- TOC entry 3846 (class 1259 OID 19008)
-- Name: idx_biglietto_id_variazione; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_biglietto_id_variazione ON public.biglietto USING btree (id_variazione);


--
-- TOC entry 3791 (class 1259 OID 18880)
-- Name: idx_pagamento_prenotazione_confermato; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_pagamento_prenotazione_confermato ON public.pagamento USING btree (id_prenotazione, is_confermato);


--
-- TOC entry 3835 (class 1259 OID 18873)
-- Name: idx_posto_segmento_liberi; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_posto_segmento_liberi ON public.posto USING btree (id_segmento) WHERE (stato = 'Libero'::public.stato_posto_enum);


--
-- TOC entry 3836 (class 1259 OID 18872)
-- Name: idx_posto_segmento_stato; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_posto_segmento_stato ON public.posto USING btree (id_segmento, stato);


--
-- TOC entry 3784 (class 1259 OID 18874)
-- Name: idx_prenotazione_utente_data; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_prenotazione_utente_data ON public.prenotazione USING btree (id_utente, data_prenotazione);


--
-- TOC entry 3808 (class 1259 OID 18878)
-- Name: idx_segmento_tratta_stato; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_segmento_tratta_stato ON public.segmento USING btree (id_tratta, stato);


--
-- TOC entry 3820 (class 1259 OID 18869)
-- Name: idx_siv_id_volo; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_siv_id_volo ON public.segmentoinvolo USING btree (id_volo);


--
-- TOC entry 3827 (class 1259 OID 18870)
-- Name: idx_ticketviaggio_codice_tk; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_ticketviaggio_codice_tk ON public.ticketviaggio USING btree (codice_tk);


--
-- TOC entry 3828 (class 1259 OID 18879)
-- Name: idx_ticketviaggio_id_prenotazione; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_ticketviaggio_id_prenotazione ON public.ticketviaggio USING btree (id_prenotazione);


--
-- TOC entry 3802 (class 1259 OID 18876)
-- Name: idx_tratta_arrivo; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_tratta_arrivo ON public.tratta USING btree (codice_iata_arrivo);


--
-- TOC entry 3803 (class 1259 OID 18875)
-- Name: idx_tratta_partenza; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_tratta_partenza ON public.tratta USING btree (codice_iata_partenza);


--
-- TOC entry 3813 (class 1259 OID 18877)
-- Name: idx_volo_stato; Type: INDEX; Schema: public; Owner: maridapetruccelli
--

CREATE INDEX idx_volo_stato ON public.volo USING btree (stato);


--
-- TOC entry 3892 (class 2620 OID 19028)
-- Name: biglietto aggiorna_stato_biglietto; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER aggiorna_stato_biglietto AFTER INSERT ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_aggiorna_stato_biglietto();


--
-- TOC entry 3893 (class 2620 OID 19009)
-- Name: biglietto check_ticket_biglietto; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER check_ticket_biglietto BEFORE INSERT OR UPDATE ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_check_ticket_biglietto();


--
-- TOC entry 3894 (class 2620 OID 19019)
-- Name: biglietto storico_su_biglietto; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER storico_su_biglietto AFTER UPDATE OF id_ticket_viaggio ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_storico_su_biglietto();


--
-- TOC entry 3885 (class 2620 OID 19088)
-- Name: prenotazione trg_aggiorna_importo_pagamento; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_aggiorna_importo_pagamento AFTER UPDATE OF importo_totale ON public.prenotazione FOR EACH ROW EXECUTE FUNCTION public.trg_aggiorna_importo_pagamento();


--
-- TOC entry 3891 (class 2620 OID 18886)
-- Name: ticketviaggio trg_aggiorna_importo_prenotazione; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_aggiorna_importo_prenotazione AFTER INSERT OR DELETE OR UPDATE ON public.ticketviaggio FOR EACH ROW EXECUTE FUNCTION public.trg_aggiorna_importo_prenotazione();


--
-- TOC entry 3895 (class 2620 OID 18884)
-- Name: biglietto trg_aggiorna_totale_ticket; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_aggiorna_totale_ticket AFTER INSERT OR DELETE OR UPDATE ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_aggiorna_importo_ticket_viaggio();


--
-- TOC entry 3888 (class 2620 OID 19134)
-- Name: volo trg_calcola_durata_volo; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_calcola_durata_volo BEFORE INSERT OR UPDATE ON public.volo FOR EACH ROW EXECUTE FUNCTION public.trg_calcola_durata_volo();


--
-- TOC entry 3889 (class 2620 OID 19091)
-- Name: volo trg_calcola_ritardo_volo; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_calcola_ritardo_volo BEFORE INSERT OR UPDATE OF data_ora_arrivo_effettivo, data_ora_arrivo_previsto ON public.volo FOR EACH ROW EXECUTE FUNCTION public.trg_calcola_ritardo_volo();


--
-- TOC entry 3896 (class 2620 OID 19132)
-- Name: biglietto trg_check_documento_valido; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_check_documento_valido BEFORE INSERT ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_check_documento_valido();


--
-- TOC entry 3897 (class 2620 OID 18890)
-- Name: biglietto trg_check_prenotazione_posti; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_check_prenotazione_posti BEFORE INSERT ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_check_prenotazione_posti();


--
-- TOC entry 3898 (class 2620 OID 18888)
-- Name: biglietto trg_check_ticket_biglietto; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_check_ticket_biglietto BEFORE INSERT OR UPDATE ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_check_ticket_biglietto();


--
-- TOC entry 3887 (class 2620 OID 18993)
-- Name: segmento trg_segmento_sin_voli; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_segmento_sin_voli AFTER UPDATE OF data_ora_partenza_prevista, data_ora_partenza_effettiva, data_ora_arrivo_previsto, data_ora_arrivo_effettivo ON public.segmento FOR EACH ROW EXECUTE FUNCTION public.trg_segmento_sin_voli();


--
-- TOC entry 3890 (class 2620 OID 18991)
-- Name: segmentoinvolo trg_segmentoinvolo_sin; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_segmentoinvolo_sin AFTER INSERT OR DELETE OR UPDATE ON public.segmentoinvolo FOR EACH ROW EXECUTE FUNCTION public.trg_segmentoinvolo_sin();


--
-- TOC entry 3899 (class 2620 OID 19021)
-- Name: biglietto trg_set_prezzo_effettivo; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_set_prezzo_effettivo BEFORE INSERT OR UPDATE OF prezzo_base ON public.biglietto FOR EACH ROW EXECUTE FUNCTION public.trg_calc_prezzo_effettivo_biglietto();


--
-- TOC entry 3886 (class 2620 OID 19086)
-- Name: pagamento trg_update_stato_prenotazione; Type: TRIGGER; Schema: public; Owner: maridapetruccelli
--

CREATE TRIGGER trg_update_stato_prenotazione AFTER INSERT OR DELETE OR UPDATE ON public.pagamento FOR EACH ROW EXECUTE FUNCTION public.trg_aggiorna_stato_prenotazione();


--
-- TOC entry 3876 (class 2606 OID 19001)
-- Name: biglietto biglietto_id_variazione_fkey; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT biglietto_id_variazione_fkey FOREIGN KEY (id_variazione) REFERENCES public.variazioneprezzo(id_variazione) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3877 (class 2606 OID 18778)
-- Name: biglietto fk_bgl_posto; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT fk_bgl_posto FOREIGN KEY (id_posto) REFERENCES public.posto(id_posto) ON DELETE SET NULL;


--
-- TOC entry 3878 (class 2606 OID 18783)
-- Name: biglietto fk_bgl_segmento; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT fk_bgl_segmento FOREIGN KEY (id_segmento) REFERENCES public.segmento(id_segmento) ON DELETE RESTRICT;


--
-- TOC entry 3879 (class 2606 OID 18773)
-- Name: biglietto fk_bgl_ticket; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.biglietto
    ADD CONSTRAINT fk_bgl_ticket FOREIGN KEY (id_ticket_viaggio) REFERENCES public.ticketviaggio(id_ticket_viaggio) ON DELETE CASCADE;


--
-- TOC entry 3865 (class 2606 OID 18609)
-- Name: classeprezzo fk_classe_segmento; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.classeprezzo
    ADD CONSTRAINT fk_classe_segmento FOREIGN KEY (id_segmento) REFERENCES public.segmento(id_segmento) ON DELETE CASCADE;


--
-- TOC entry 3880 (class 2606 OID 18807)
-- Name: pagamentoaccessorio fk_pa_accessorio; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.pagamentoaccessorio
    ADD CONSTRAINT fk_pa_accessorio FOREIGN KEY (id_accessorio) REFERENCES public.accessorio(id_accessorio) ON DELETE RESTRICT;


--
-- TOC entry 3881 (class 2606 OID 18802)
-- Name: pagamentoaccessorio fk_pa_biglietto; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.pagamentoaccessorio
    ADD CONSTRAINT fk_pa_biglietto FOREIGN KEY (id_biglietto) REFERENCES public.biglietto(id_biglietto) ON DELETE CASCADE;


--
-- TOC entry 3860 (class 2606 OID 18512)
-- Name: pagamento fk_pagamento_prenotazione; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.pagamento
    ADD CONSTRAINT fk_pagamento_prenotazione FOREIGN KEY (id_prenotazione) REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE;


--
-- TOC entry 3857 (class 2606 OID 18447)
-- Name: fidelizzatovolare fk_passeggero; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.fidelizzatovolare
    ADD CONSTRAINT fk_passeggero FOREIGN KEY (id_passeggero) REFERENCES public.passeggero(id_passeggero) ON DELETE CASCADE;


--
-- TOC entry 3875 (class 2606 OID 18743)
-- Name: posto fk_posto_segmento; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.posto
    ADD CONSTRAINT fk_posto_segmento FOREIGN KEY (id_segmento) REFERENCES public.segmento(id_segmento) ON DELETE CASCADE;


--
-- TOC entry 3858 (class 2606 OID 18471)
-- Name: prenotazione fk_prenotazione_utente; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT fk_prenotazione_utente FOREIGN KEY (id_utente) REFERENCES public.utente(id_utente) ON DELETE SET NULL;


--
-- TOC entry 3870 (class 2606 OID 18680)
-- Name: prenotazionevolo fk_pv_prenotazione; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.prenotazionevolo
    ADD CONSTRAINT fk_pv_prenotazione FOREIGN KEY (id_prenotazione) REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE;


--
-- TOC entry 3871 (class 2606 OID 18685)
-- Name: prenotazionevolo fk_pv_volo; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.prenotazionevolo
    ADD CONSTRAINT fk_pv_volo FOREIGN KEY (id_volo) REFERENCES public.volo(id_volo) ON DELETE CASCADE;


--
-- TOC entry 3882 (class 2606 OID 18854)
-- Name: storicobiglietto fk_sb_biglietto; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicobiglietto
    ADD CONSTRAINT fk_sb_biglietto FOREIGN KEY (id_biglietto) REFERENCES public.biglietto(id_biglietto) ON DELETE CASCADE;


--
-- TOC entry 3883 (class 2606 OID 18864)
-- Name: storicobiglietto fk_sb_nuovo_passeggero; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicobiglietto
    ADD CONSTRAINT fk_sb_nuovo_passeggero FOREIGN KEY (id_nuovo_passeggero) REFERENCES public.passeggero(id_passeggero) ON DELETE RESTRICT;


--
-- TOC entry 3884 (class 2606 OID 18859)
-- Name: storicobiglietto fk_sb_vecchio_passeggero; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicobiglietto
    ADD CONSTRAINT fk_sb_vecchio_passeggero FOREIGN KEY (id_vecchio_passeggero) REFERENCES public.passeggero(id_passeggero) ON DELETE RESTRICT;


--
-- TOC entry 3866 (class 2606 OID 18652)
-- Name: scalo fk_scalo_aeroporto; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.scalo
    ADD CONSTRAINT fk_scalo_aeroporto FOREIGN KEY (codice_iata) REFERENCES public.aeroporto(codice_iata) ON DELETE RESTRICT;


--
-- TOC entry 3867 (class 2606 OID 18647)
-- Name: scalo fk_scalo_volo; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.scalo
    ADD CONSTRAINT fk_scalo_volo FOREIGN KEY (id_volo) REFERENCES public.volo(id_volo) ON DELETE CASCADE;


--
-- TOC entry 3863 (class 2606 OID 18589)
-- Name: segmento fk_segmento_aereo; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmento
    ADD CONSTRAINT fk_segmento_aereo FOREIGN KEY (matricola_aereo) REFERENCES public.aereo(matricola) ON DELETE RESTRICT;


--
-- TOC entry 3864 (class 2606 OID 18584)
-- Name: segmento fk_segmento_tratta; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmento
    ADD CONSTRAINT fk_segmento_tratta FOREIGN KEY (id_tratta) REFERENCES public.tratta(id_tratta) ON DELETE RESTRICT;


--
-- TOC entry 3868 (class 2606 OID 18665)
-- Name: segmentoinvolo fk_siv_segmento; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmentoinvolo
    ADD CONSTRAINT fk_siv_segmento FOREIGN KEY (id_segmento) REFERENCES public.segmento(id_segmento) ON DELETE CASCADE;


--
-- TOC entry 3869 (class 2606 OID 18670)
-- Name: segmentoinvolo fk_siv_volo; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.segmentoinvolo
    ADD CONSTRAINT fk_siv_volo FOREIGN KEY (id_volo) REFERENCES public.volo(id_volo) ON DELETE CASCADE;


--
-- TOC entry 3859 (class 2606 OID 18486)
-- Name: storicoprenotazione fk_storico_prenotazione; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.storicoprenotazione
    ADD CONSTRAINT fk_storico_prenotazione FOREIGN KEY (id_prenotazione) REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE;


--
-- TOC entry 3872 (class 2606 OID 18716)
-- Name: ticketviaggio fk_ticket_passeggero; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.ticketviaggio
    ADD CONSTRAINT fk_ticket_passeggero FOREIGN KEY (id_passeggero) REFERENCES public.passeggero(id_passeggero) ON DELETE CASCADE;


--
-- TOC entry 3873 (class 2606 OID 18711)
-- Name: ticketviaggio fk_ticket_prenotazione; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.ticketviaggio
    ADD CONSTRAINT fk_ticket_prenotazione FOREIGN KEY (id_prenotazione) REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE;


--
-- TOC entry 3874 (class 2606 OID 18721)
-- Name: ticketviaggio fk_ticket_volo; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.ticketviaggio
    ADD CONSTRAINT fk_ticket_volo FOREIGN KEY (id_volo) REFERENCES public.volo(id_volo) ON DELETE CASCADE;


--
-- TOC entry 3861 (class 2606 OID 18559)
-- Name: tratta fk_tratta_arrivo; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.tratta
    ADD CONSTRAINT fk_tratta_arrivo FOREIGN KEY (codice_iata_arrivo) REFERENCES public.aeroporto(codice_iata) ON DELETE RESTRICT;


--
-- TOC entry 3862 (class 2606 OID 18554)
-- Name: tratta fk_tratta_partenza; Type: FK CONSTRAINT; Schema: public; Owner: maridapetruccelli
--

ALTER TABLE ONLY public.tratta
    ADD CONSTRAINT fk_tratta_partenza FOREIGN KEY (codice_iata_partenza) REFERENCES public.aeroporto(codice_iata) ON DELETE RESTRICT;


--
-- TOC entry 4092 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: maridapetruccelli
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2025-09-19 12:02:28 CEST

--
-- PostgreSQL database dump complete
--

