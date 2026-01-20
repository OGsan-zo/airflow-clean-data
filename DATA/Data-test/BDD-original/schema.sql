--
-- PostgreSQL database dump
--

\restrict YMephjXesQWndBPHmshzBUBX4Sbr3knqVz3nXIR0XBliXL5cTTRdiBX1AmEDNu3

-- Dumped from database version 14.20 (Ubuntu 14.20-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.20 (Ubuntu 14.20-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bacc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bacc (
    id integer NOT NULL,
    numero character varying(255) DEFAULT NULL::character varying,
    annee integer NOT NULL,
    serie character varying(50) NOT NULL
);


ALTER TABLE public.bacc OWNER TO postgres;

--
-- Name: bacc_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bacc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bacc_id_seq OWNER TO postgres;

--
-- Name: bacc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bacc_id_seq OWNED BY public.bacc.id;


--
-- Name: cin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cin (
    id integer NOT NULL,
    numero integer NOT NULL,
    date_cin timestamp(0) without time zone NOT NULL,
    lieu character varying(255) NOT NULL,
    ancien_date timestamp(0) without time zone NOT NULL,
    nouveau_date timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.cin OWNER TO postgres;

--
-- Name: cin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cin_id_seq OWNER TO postgres;

--
-- Name: cin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cin_id_seq OWNED BY public.cin.id;


--
-- Name: droits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.droits (
    id integer NOT NULL,
    type_droit_id integer NOT NULL,
    reference character varying(255) NOT NULL,
    date_versement timestamp(0) without time zone NOT NULL,
    montant double precision NOT NULL,
    utilisateur_id integer NOT NULL,
    etudiant_id integer NOT NULL,
    annee integer NOT NULL
);


ALTER TABLE public.droits OWNER TO postgres;

--
-- Name: droits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.droits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.droits_id_seq OWNER TO postgres;

--
-- Name: droits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.droits_id_seq OWNED BY public.droits.id;


--
-- Name: ecolages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ecolages (
    id integer NOT NULL,
    formations_id integer NOT NULL,
    montant double precision NOT NULL,
    date_ecolage timestamp(0) without time zone DEFAULT NULL::timestamp without time zone
);


ALTER TABLE public.ecolages OWNER TO postgres;

--
-- Name: ecolages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ecolages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ecolages_id_seq OWNER TO postgres;

--
-- Name: ecolages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ecolages_id_seq OWNED BY public.ecolages.id;


--
-- Name: etudiants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.etudiants (
    id integer NOT NULL,
    cin_id integer,
    bacc_id integer NOT NULL,
    propos_id integer NOT NULL,
    nom character varying(255) NOT NULL,
    prenom character varying(255) NOT NULL,
    date_naissance timestamp(0) without time zone NOT NULL,
    lieu_naissance character varying(255) NOT NULL,
    sexe_id integer NOT NULL,
    status_etudiant_id integer
);


ALTER TABLE public.etudiants OWNER TO postgres;

--
-- Name: etudiants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.etudiants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.etudiants_id_seq OWNER TO postgres;

--
-- Name: etudiants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.etudiants_id_seq OWNED BY public.etudiants.id;


--
-- Name: formation_etudiants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.formation_etudiants (
    id integer NOT NULL,
    etudiant_id integer NOT NULL,
    formation_id integer NOT NULL,
    date_formation timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.formation_etudiants OWNER TO postgres;

--
-- Name: formation_etudiants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.formation_etudiants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.formation_etudiants_id_seq OWNER TO postgres;

--
-- Name: formation_etudiants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.formation_etudiants_id_seq OWNED BY public.formation_etudiants.id;


--
-- Name: formations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.formations (
    id integer NOT NULL,
    type_formation_id integer NOT NULL,
    nom character varying(100) NOT NULL
);


ALTER TABLE public.formations OWNER TO postgres;

--
-- Name: formations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.formations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.formations_id_seq OWNER TO postgres;

--
-- Name: formations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.formations_id_seq OWNED BY public.formations.id;


--
-- Name: inscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inscriptions (
    id integer NOT NULL,
    etudiant_id integer NOT NULL,
    utilisateur_id integer NOT NULL,
    date_inscription timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.inscriptions OWNER TO postgres;

--
-- Name: inscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inscriptions_id_seq OWNER TO postgres;

--
-- Name: inscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inscriptions_id_seq OWNED BY public.inscriptions.id;


--
-- Name: inscrits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inscrits (
    id integer NOT NULL,
    utilisateur_id integer NOT NULL,
    etudiant_id integer NOT NULL,
    description character varying(255) NOT NULL,
    date_inscription timestamp(0) without time zone NOT NULL,
    matricule character varying(255)
);


ALTER TABLE public.inscrits OWNER TO postgres;

--
-- Name: inscrits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inscrits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inscrits_id_seq OWNER TO postgres;

--
-- Name: inscrits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inscrits_id_seq OWNED BY public.inscrits.id;


--
-- Name: mentions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mentions (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    abr character varying(10)
);


ALTER TABLE public.mentions OWNER TO postgres;

--
-- Name: mentions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mentions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mentions_id_seq OWNER TO postgres;

--
-- Name: mentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mentions_id_seq OWNED BY public.mentions.id;


--
-- Name: niveau_etudiants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.niveau_etudiants (
    id integer NOT NULL,
    niveau_id integer NOT NULL,
    mention_id integer NOT NULL,
    annee integer NOT NULL,
    date_insertion timestamp(0) without time zone NOT NULL,
    etudiant_id integer NOT NULL,
    status_etudiant_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.niveau_etudiants OWNER TO postgres;

--
-- Name: niveau_etudiants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.niveau_etudiants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.niveau_etudiants_id_seq OWNER TO postgres;

--
-- Name: niveau_etudiants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.niveau_etudiants_id_seq OWNED BY public.niveau_etudiants.id;


--
-- Name: niveaux; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.niveaux (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    type smallint NOT NULL,
    grade smallint NOT NULL
);


ALTER TABLE public.niveaux OWNER TO postgres;

--
-- Name: niveaux_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.niveaux_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.niveaux_id_seq OWNER TO postgres;

--
-- Name: niveaux_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.niveaux_id_seq OWNED BY public.niveaux.id;


--
-- Name: parcours; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parcours (
    id integer NOT NULL,
    mention_id integer NOT NULL,
    nom character varying(100) NOT NULL
);


ALTER TABLE public.parcours OWNER TO postgres;

--
-- Name: parcours_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parcours_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parcours_id_seq OWNER TO postgres;

--
-- Name: parcours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parcours_id_seq OWNED BY public.parcours.id;


--
-- Name: payements_ecolages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payements_ecolages (
    id integer NOT NULL,
    etudiant_id integer NOT NULL,
    reference character varying(255) NOT NULL,
    datepayements timestamp(0) without time zone NOT NULL,
    montant double precision NOT NULL,
    tranche integer NOT NULL,
    utilisateur_id integer NOT NULL,
    annee integer NOT NULL
);


ALTER TABLE public.payements_ecolages OWNER TO postgres;

--
-- Name: payements_ecolages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payements_ecolages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payements_ecolages_id_seq OWNER TO postgres;

--
-- Name: payements_ecolages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payements_ecolages_id_seq OWNED BY public.payements_ecolages.id;


--
-- Name: propos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.propos (
    id integer NOT NULL,
    adresse character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    sexe character varying(50) NOT NULL
);


ALTER TABLE public.propos OWNER TO postgres;

--
-- Name: propos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.propos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.propos_id_seq OWNER TO postgres;

--
-- Name: propos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.propos_id_seq OWNED BY public.propos.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.role OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_id_seq OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.role_id_seq OWNED BY public.role.id;


--
-- Name: sexes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sexes (
    id integer NOT NULL,
    nom character varying(50) NOT NULL
);


ALTER TABLE public.sexes OWNER TO postgres;

--
-- Name: sexes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sexes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sexes_id_seq OWNER TO postgres;

--
-- Name: sexes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sexes_id_seq OWNED BY public.sexes.id;


--
-- Name: status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.status OWNER TO postgres;

--
-- Name: status_etudiants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_etudiants (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.status_etudiants OWNER TO postgres;

--
-- Name: status_etudiants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_etudiants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.status_etudiants_id_seq OWNER TO postgres;

--
-- Name: status_etudiants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_etudiants_id_seq OWNED BY public.status_etudiants.id;


--
-- Name: status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.status_id_seq OWNER TO postgres;

--
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_id_seq OWNED BY public.status.id;


--
-- Name: type_droits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.type_droits (
    id integer NOT NULL,
    nom character varying(100) NOT NULL
);


ALTER TABLE public.type_droits OWNER TO postgres;

--
-- Name: type_droits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.type_droits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.type_droits_id_seq OWNER TO postgres;

--
-- Name: type_droits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.type_droits_id_seq OWNED BY public.type_droits.id;


--
-- Name: type_formations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.type_formations (
    id integer NOT NULL,
    nom character varying(100) NOT NULL
);


ALTER TABLE public.type_formations OWNER TO postgres;

--
-- Name: type_formations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.type_formations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.type_formations_id_seq OWNER TO postgres;

--
-- Name: type_formations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.type_formations_id_seq OWNED BY public.type_formations.id;


--
-- Name: utilisateur; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.utilisateur (
    id integer NOT NULL,
    role_id integer NOT NULL,
    status_id integer,
    email character varying(255) NOT NULL,
    mdp character varying(255) NOT NULL,
    nom character varying(255) NOT NULL,
    prenom character varying(255) NOT NULL,
    date_creation timestamp(0) without time zone DEFAULT NULL::timestamp without time zone
);


ALTER TABLE public.utilisateur OWNER TO postgres;

--
-- Name: utilisateur_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.utilisateur_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.utilisateur_id_seq OWNER TO postgres;

--
-- Name: utilisateur_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.utilisateur_id_seq OWNED BY public.utilisateur.id;


--
-- Name: bacc id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bacc ALTER COLUMN id SET DEFAULT nextval('public.bacc_id_seq'::regclass);


--
-- Name: cin id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cin ALTER COLUMN id SET DEFAULT nextval('public.cin_id_seq'::regclass);


--
-- Name: droits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droits ALTER COLUMN id SET DEFAULT nextval('public.droits_id_seq'::regclass);


--
-- Name: ecolages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecolages ALTER COLUMN id SET DEFAULT nextval('public.ecolages_id_seq'::regclass);


--
-- Name: etudiants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etudiants ALTER COLUMN id SET DEFAULT nextval('public.etudiants_id_seq'::regclass);


--
-- Name: formation_etudiants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formation_etudiants ALTER COLUMN id SET DEFAULT nextval('public.formation_etudiants_id_seq'::regclass);


--
-- Name: formations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formations ALTER COLUMN id SET DEFAULT nextval('public.formations_id_seq'::regclass);


--
-- Name: inscriptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscriptions ALTER COLUMN id SET DEFAULT nextval('public.inscriptions_id_seq'::regclass);


--
-- Name: inscrits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscrits ALTER COLUMN id SET DEFAULT nextval('public.inscrits_id_seq'::regclass);


--
-- Name: mentions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mentions ALTER COLUMN id SET DEFAULT nextval('public.mentions_id_seq'::regclass);


--
-- Name: niveau_etudiants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveau_etudiants ALTER COLUMN id SET DEFAULT nextval('public.niveau_etudiants_id_seq'::regclass);


--
-- Name: niveaux id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveaux ALTER COLUMN id SET DEFAULT nextval('public.niveaux_id_seq'::regclass);


--
-- Name: parcours id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcours ALTER COLUMN id SET DEFAULT nextval('public.parcours_id_seq'::regclass);


--
-- Name: payements_ecolages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payements_ecolages ALTER COLUMN id SET DEFAULT nextval('public.payements_ecolages_id_seq'::regclass);


--
-- Name: propos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propos ALTER COLUMN id SET DEFAULT nextval('public.propos_id_seq'::regclass);


--
-- Name: role id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role ALTER COLUMN id SET DEFAULT nextval('public.role_id_seq'::regclass);


--
-- Name: sexes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sexes ALTER COLUMN id SET DEFAULT nextval('public.sexes_id_seq'::regclass);


--
-- Name: status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status ALTER COLUMN id SET DEFAULT nextval('public.status_id_seq'::regclass);


--
-- Name: status_etudiants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_etudiants ALTER COLUMN id SET DEFAULT nextval('public.status_etudiants_id_seq'::regclass);


--
-- Name: type_droits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_droits ALTER COLUMN id SET DEFAULT nextval('public.type_droits_id_seq'::regclass);


--
-- Name: type_formations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_formations ALTER COLUMN id SET DEFAULT nextval('public.type_formations_id_seq'::regclass);


--
-- Name: utilisateur id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur ALTER COLUMN id SET DEFAULT nextval('public.utilisateur_id_seq'::regclass);


--
-- Name: bacc bacc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bacc
    ADD CONSTRAINT bacc_pkey PRIMARY KEY (id);


--
-- Name: cin cin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cin
    ADD CONSTRAINT cin_pkey PRIMARY KEY (id);


--
-- Name: droits droits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droits
    ADD CONSTRAINT droits_pkey PRIMARY KEY (id);


--
-- Name: ecolages ecolages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecolages
    ADD CONSTRAINT ecolages_pkey PRIMARY KEY (id);


--
-- Name: etudiants etudiants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etudiants
    ADD CONSTRAINT etudiants_pkey PRIMARY KEY (id);


--
-- Name: formation_etudiants formation_etudiants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formation_etudiants
    ADD CONSTRAINT formation_etudiants_pkey PRIMARY KEY (id);


--
-- Name: formations formations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formations
    ADD CONSTRAINT formations_pkey PRIMARY KEY (id);


--
-- Name: inscriptions inscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscriptions
    ADD CONSTRAINT inscriptions_pkey PRIMARY KEY (id);


--
-- Name: inscrits inscrits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscrits
    ADD CONSTRAINT inscrits_pkey PRIMARY KEY (id);


--
-- Name: mentions mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT mentions_pkey PRIMARY KEY (id);


--
-- Name: niveau_etudiants niveau_etudiants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveau_etudiants
    ADD CONSTRAINT niveau_etudiants_pkey PRIMARY KEY (id);


--
-- Name: niveaux niveaux_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveaux
    ADD CONSTRAINT niveaux_pkey PRIMARY KEY (id);


--
-- Name: parcours parcours_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcours
    ADD CONSTRAINT parcours_pkey PRIMARY KEY (id);


--
-- Name: payements_ecolages payements_ecolages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payements_ecolages
    ADD CONSTRAINT payements_ecolages_pkey PRIMARY KEY (id);


--
-- Name: propos propos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propos
    ADD CONSTRAINT propos_pkey PRIMARY KEY (id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: sexes sexes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sexes
    ADD CONSTRAINT sexes_pkey PRIMARY KEY (id);


--
-- Name: status_etudiants status_etudiants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_etudiants
    ADD CONSTRAINT status_etudiants_pkey PRIMARY KEY (id);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- Name: type_droits type_droits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_droits
    ADD CONSTRAINT type_droits_pkey PRIMARY KEY (id);


--
-- Name: type_formations type_formations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_formations
    ADD CONSTRAINT type_formations_pkey PRIMARY KEY (id);


--
-- Name: utilisateur utilisateur_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT utilisateur_pkey PRIMARY KEY (id);


--
-- Name: idx_1d1c63b36bf700bd; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_1d1c63b36bf700bd ON public.utilisateur USING btree (status_id);


--
-- Name: idx_1d1c63b3d60322ac; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_1d1c63b3d60322ac ON public.utilisateur USING btree (role_id);


--
-- Name: idx_227c02eb2cec171f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_227c02eb2cec171f ON public.etudiants USING btree (bacc_id);


--
-- Name: idx_227c02eb75eb8397; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_227c02eb75eb8397 ON public.etudiants USING btree (propos_id);


--
-- Name: idx_227c02ebe9795579; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_227c02ebe9795579 ON public.etudiants USING btree (cin_id);


--
-- Name: idx_2644257fddeab1a3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_2644257fddeab1a3 ON public.inscrits USING btree (etudiant_id);


--
-- Name: idx_2644257ffb88e14f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_2644257ffb88e14f ON public.inscrits USING btree (utilisateur_id);


--
-- Name: idx_40902137d543922b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_40902137d543922b ON public.formations USING btree (type_formation_id);


--
-- Name: idx_70ade61d7a4147f0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_70ade61d7a4147f0 ON public.niveau_etudiants USING btree (mention_id);


--
-- Name: idx_70ade61db3e9c81; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_70ade61db3e9c81 ON public.niveau_etudiants USING btree (niveau_id);


--
-- Name: idx_74e0281cddeab1a3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_74e0281cddeab1a3 ON public.inscriptions USING btree (etudiant_id);


--
-- Name: idx_74e0281cfb88e14f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_74e0281cfb88e14f ON public.inscriptions USING btree (utilisateur_id);


--
-- Name: idx_7a9d4ce9756148c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_7a9d4ce9756148c ON public.droits USING btree (type_droit_id);


--
-- Name: idx_7a9d4ceddeab1a3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_7a9d4ceddeab1a3 ON public.droits USING btree (etudiant_id);


--
-- Name: idx_7a9d4cefb88e14f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_7a9d4cefb88e14f ON public.droits USING btree (utilisateur_id);


--
-- Name: idx_99b1dee37a4147f0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_99b1dee37a4147f0 ON public.parcours USING btree (mention_id);


--
-- Name: idx_a6d31440ddeab1a3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_a6d31440ddeab1a3 ON public.payements_ecolages USING btree (etudiant_id);


--
-- Name: idx_a6d31440fb88e14f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_a6d31440fb88e14f ON public.payements_ecolages USING btree (utilisateur_id);


--
-- Name: idx_e80152365200282e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_e80152365200282e ON public.formation_etudiants USING btree (formation_id);


--
-- Name: idx_e8015236ddeab1a3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_e8015236ddeab1a3 ON public.formation_etudiants USING btree (etudiant_id);


--
-- Name: idx_fd93f2aa3bf5b0c2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fd93f2aa3bf5b0c2 ON public.ecolages USING btree (formations_id);


--
-- Name: utilisateur fk_1d1c63b36bf700bd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT fk_1d1c63b36bf700bd FOREIGN KEY (status_id) REFERENCES public.status(id);


--
-- Name: utilisateur fk_1d1c63b3d60322ac; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT fk_1d1c63b3d60322ac FOREIGN KEY (role_id) REFERENCES public.role(id);


--
-- Name: etudiants fk_227c02eb2cec171f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etudiants
    ADD CONSTRAINT fk_227c02eb2cec171f FOREIGN KEY (bacc_id) REFERENCES public.bacc(id);


--
-- Name: etudiants fk_227c02eb75eb8397; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etudiants
    ADD CONSTRAINT fk_227c02eb75eb8397 FOREIGN KEY (propos_id) REFERENCES public.propos(id);


--
-- Name: etudiants fk_227c02ebe9795579; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etudiants
    ADD CONSTRAINT fk_227c02ebe9795579 FOREIGN KEY (cin_id) REFERENCES public.cin(id);


--
-- Name: inscrits fk_2644257fddeab1a3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscrits
    ADD CONSTRAINT fk_2644257fddeab1a3 FOREIGN KEY (etudiant_id) REFERENCES public.etudiants(id);


--
-- Name: inscrits fk_2644257ffb88e14f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscrits
    ADD CONSTRAINT fk_2644257ffb88e14f FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(id);


--
-- Name: formations fk_40902137d543922b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formations
    ADD CONSTRAINT fk_40902137d543922b FOREIGN KEY (type_formation_id) REFERENCES public.type_formations(id);


--
-- Name: niveau_etudiants fk_70ade61d7a4147f0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveau_etudiants
    ADD CONSTRAINT fk_70ade61d7a4147f0 FOREIGN KEY (mention_id) REFERENCES public.mentions(id);


--
-- Name: niveau_etudiants fk_70ade61db3e9c81; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveau_etudiants
    ADD CONSTRAINT fk_70ade61db3e9c81 FOREIGN KEY (niveau_id) REFERENCES public.niveaux(id);


--
-- Name: inscriptions fk_74e0281cddeab1a3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscriptions
    ADD CONSTRAINT fk_74e0281cddeab1a3 FOREIGN KEY (etudiant_id) REFERENCES public.etudiants(id);


--
-- Name: inscriptions fk_74e0281cfb88e14f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscriptions
    ADD CONSTRAINT fk_74e0281cfb88e14f FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(id);


--
-- Name: droits fk_7a9d4ce9756148c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droits
    ADD CONSTRAINT fk_7a9d4ce9756148c FOREIGN KEY (type_droit_id) REFERENCES public.type_droits(id);


--
-- Name: droits fk_7a9d4ceddeab1a3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droits
    ADD CONSTRAINT fk_7a9d4ceddeab1a3 FOREIGN KEY (etudiant_id) REFERENCES public.etudiants(id);


--
-- Name: droits fk_7a9d4cefb88e14f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droits
    ADD CONSTRAINT fk_7a9d4cefb88e14f FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(id);


--
-- Name: parcours fk_99b1dee37a4147f0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parcours
    ADD CONSTRAINT fk_99b1dee37a4147f0 FOREIGN KEY (mention_id) REFERENCES public.mentions(id);


--
-- Name: payements_ecolages fk_a6d31440ddeab1a3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payements_ecolages
    ADD CONSTRAINT fk_a6d31440ddeab1a3 FOREIGN KEY (etudiant_id) REFERENCES public.etudiants(id);


--
-- Name: payements_ecolages fk_a6d31440fb88e14f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payements_ecolages
    ADD CONSTRAINT fk_a6d31440fb88e14f FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(id);


--
-- Name: formation_etudiants fk_e80152365200282e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formation_etudiants
    ADD CONSTRAINT fk_e80152365200282e FOREIGN KEY (formation_id) REFERENCES public.formations(id);


--
-- Name: formation_etudiants fk_e8015236ddeab1a3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formation_etudiants
    ADD CONSTRAINT fk_e8015236ddeab1a3 FOREIGN KEY (etudiant_id) REFERENCES public.etudiants(id);


--
-- Name: etudiants fk_etudiants_sexe; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etudiants
    ADD CONSTRAINT fk_etudiants_sexe FOREIGN KEY (sexe_id) REFERENCES public.sexes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ecolages fk_fd93f2aa3bf5b0c2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecolages
    ADD CONSTRAINT fk_fd93f2aa3bf5b0c2 FOREIGN KEY (formations_id) REFERENCES public.formations(id);


--
-- Name: niveau_etudiants fk_niveau_etudiants_status_etudiant; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveau_etudiants
    ADD CONSTRAINT fk_niveau_etudiants_status_etudiant FOREIGN KEY (status_etudiant_id) REFERENCES public.status_etudiants(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: niveau_etudiants niveau_etudiants_etudiant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveau_etudiants
    ADD CONSTRAINT niveau_etudiants_etudiant_id_fkey FOREIGN KEY (etudiant_id) REFERENCES public.etudiants(id);


--
-- PostgreSQL database dump complete
--

\unrestrict YMephjXesQWndBPHmshzBUBX4Sbr3knqVz3nXIR0XBliXL5cTTRdiBX1AmEDNu3

