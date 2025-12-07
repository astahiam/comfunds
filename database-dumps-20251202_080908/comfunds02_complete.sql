--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Postgres.app)
-- Dumped by pg_dump version 16.3 (Postgres.app)

-- Started on 2025-12-02 08:09:10 WIB

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

DROP DATABASE IF EXISTS comfunds02;
--
-- TOC entry 3881 (class 1262 OID 17424)
-- Name: comfunds02; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE comfunds02 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE comfunds02 OWNER TO postgres;

\connect comfunds02

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

--
-- TOC entry 2 (class 3079 OID 17924)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3882 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 239 (class 1255 OID 24750)
-- Name: update_images_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_images_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_images_updated_at() OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 17970)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 224 (class 1259 OID 18153)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    operation character varying(20) NOT NULL,
    user_id uuid NOT NULL,
    ip_address inet,
    user_agent text,
    changes jsonb,
    old_values jsonb,
    new_values jsonb,
    reason text,
    status character varying(20) DEFAULT 'SUCCESS'::character varying NOT NULL,
    error_msg text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT audit_logs_operation_check CHECK (((operation)::text = ANY ((ARRAY['CREATE'::character varying, 'READ'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'LOGIN'::character varying, 'LOGOUT'::character varying])::text[]))),
    CONSTRAINT audit_logs_status_check CHECK (((status)::text = ANY ((ARRAY['SUCCESS'::character varying, 'FAILED'::character varying, 'UNAUTHORIZED'::character varying])::text[])))
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 17996)
-- Name: businesses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.businesses (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    business_type character varying(100) NOT NULL,
    description text,
    owner_id uuid NOT NULL,
    cooperative_id uuid NOT NULL,
    registration_documents jsonb DEFAULT '{}'::jsonb,
    approval_status character varying(20) DEFAULT 'pending'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    business_image character varying(500),
    registration_number character varying(100),
    tax_id character varying(50),
    legal_structure character varying(100),
    industry character varying(100),
    sector character varying(100),
    address text,
    phone character varying(50),
    email character varying(255),
    website character varying(500),
    established_date date,
    employee_count integer DEFAULT 0,
    annual_revenue numeric(15,2) DEFAULT 0.00,
    currency character varying(3) DEFAULT 'IDR'::character varying,
    bank_account character varying(100),
    business_license character varying(500),
    documents jsonb DEFAULT '[]'::jsonb,
    status character varying(50) DEFAULT 'draft'::character varying,
    approved_by uuid,
    approved_at timestamp with time zone,
    rejection_reason text,
    metadata jsonb DEFAULT '{}'::jsonb,
    performance_metrics jsonb DEFAULT '{}'::jsonb,
    compliance_status jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT chk_approval_status CHECK (((approval_status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT chk_business_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending_approval'::character varying, 'approved'::character varying, 'rejected'::character varying, 'suspended'::character varying, 'active'::character varying, 'inactive'::character varying])::text[])))
);


ALTER TABLE public.businesses OWNER TO postgres;

--
-- TOC entry 3883 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN businesses.business_image; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.businesses.business_image IS 'Business logo/image URL from AWS S3';


--
-- TOC entry 217 (class 1259 OID 17952)
-- Name: cooperatives; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cooperatives (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    registration_number character varying(100) NOT NULL,
    address text NOT NULL,
    phone character varying(50) NOT NULL,
    email character varying(255) NOT NULL,
    bank_account character varying(100) NOT NULL,
    profit_sharing_policy jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    cooperative_image character varying(500)
);


ALTER TABLE public.cooperatives OWNER TO postgres;

--
-- TOC entry 3884 (class 0 OID 0)
-- Dependencies: 217
-- Name: COLUMN cooperatives.cooperative_image; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cooperatives.cooperative_image IS 'Cooperative logo/image URL from AWS S3';


--
-- TOC entry 220 (class 1259 OID 18061)
-- Name: global_transaction_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.global_transaction_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.global_transaction_seq OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 24752)
-- Name: idempotency_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.idempotency_keys (
    id character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    endpoint character varying(255) NOT NULL,
    request_hash character varying(64) NOT NULL,
    response_data jsonb,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone NOT NULL,
    sequence_number integer NOT NULL,
    table_name character varying(100) NOT NULL,
    random_suffix character varying(5) NOT NULL
);


ALTER TABLE public.idempotency_keys OWNER TO postgres;

--
-- TOC entry 3885 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE idempotency_keys; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.idempotency_keys IS 'Stores idempotency keys to prevent duplicate transactions';


--
-- TOC entry 3886 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN idempotency_keys.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.id IS 'Format: yyyymmddhhmm + sequence_number + table_name + 5_random_chars';


--
-- TOC entry 3887 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN idempotency_keys.sequence_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.sequence_number IS 'Auto-incrementing sequence number';


--
-- TOC entry 3888 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN idempotency_keys.table_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.table_name IS 'Target table name for the transaction';


--
-- TOC entry 3889 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN idempotency_keys.random_suffix; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.random_suffix IS '5 random alphanumeric characters';


--
-- TOC entry 227 (class 1259 OID 24765)
-- Name: idempotency_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.idempotency_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.idempotency_sequence OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 24738)
-- Name: images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    image_url character varying(500) NOT NULL,
    image_name character varying(255) NOT NULL,
    used_by character varying(50) NOT NULL,
    image_size bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.images OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 18114)
-- Name: investment_returns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.investment_returns (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    investment_id uuid NOT NULL,
    distribution_id uuid NOT NULL,
    return_amount numeric(15,2) NOT NULL,
    return_percentage numeric(5,2) NOT NULL,
    payment_date timestamp with time zone,
    status character varying(20) DEFAULT 'pending'::character varying,
    transaction_ref character varying(50) DEFAULT ((('RTN-'::text || (EXTRACT(epoch FROM CURRENT_TIMESTAMP))::bigint) || '-'::text) || nextval('public.global_transaction_seq'::regclass)) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_return_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'paid'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT investment_returns_return_amount_check CHECK ((return_amount >= (0)::numeric)),
    CONSTRAINT investment_returns_return_percentage_check CHECK ((return_percentage >= (0)::numeric))
);


ALTER TABLE public.investment_returns OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 18062)
-- Name: investments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.investments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    investor_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    investment_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    profit_sharing_percentage numeric(5,2) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    transaction_ref character varying(50) DEFAULT ((('TXN-'::text || (EXTRACT(epoch FROM CURRENT_TIMESTAMP))::bigint) || '-'::text) || nextval('public.global_transaction_seq'::regclass)) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_investment_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'refunded'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT investments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT investments_profit_sharing_percentage_check CHECK (((profit_sharing_percentage >= (0)::numeric) AND (profit_sharing_percentage <= (100)::numeric)))
);


ALTER TABLE public.investments OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 18097)
-- Name: profit_distributions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profit_distributions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    business_profit numeric(15,2) NOT NULL,
    distribution_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    total_distributed numeric(15,2) NOT NULL,
    status character varying(20) DEFAULT 'calculated'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_distribution_status CHECK (((status)::text = ANY ((ARRAY['calculated'::character varying, 'approved'::character varying, 'distributed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT profit_distributions_total_distributed_check CHECK ((total_distributed >= (0)::numeric))
);


ALTER TABLE public.profit_distributions OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 18027)
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    business_id uuid NOT NULL,
    funding_goal numeric(15,2),
    minimum_funding numeric(15,2),
    current_funding numeric(15,2) DEFAULT 0 NOT NULL,
    funding_deadline timestamp with time zone,
    profit_sharing_ratio jsonb DEFAULT '{"business": 30, "investor": 70}'::jsonb NOT NULL,
    project_type character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying,
    milestones jsonb DEFAULT '[]'::jsonb,
    documents jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    project_image_1 character varying(500),
    project_image_2 character varying(500),
    project_image_3 character varying(500),
    min_investment numeric(15,2),
    risk_level character varying(20),
    investment_period integer,
    expected_return character varying(50),
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    target_amount numeric(15,2),
    raised_amount numeric(15,2) DEFAULT 0,
    category character varying(100),
    owner_id uuid,
    cooperative_id uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    approval_status character varying(20) DEFAULT 'pending'::character varying,
    rejected_by uuid,
    rejected_at timestamp with time zone,
    rejection_reason text,
    reviewer_comments text,
    sharia_compliant boolean DEFAULT false,
    CONSTRAINT chk_project_approval_status CHECK (((approval_status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT chk_project_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'submitted'::character varying, 'approved'::character varying, 'active'::character varying, 'funded'::character varying, 'closed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT chk_project_type CHECK (((project_type)::text = ANY ((ARRAY['startup'::character varying, 'expansion'::character varying, 'equipment'::character varying])::text[]))),
    CONSTRAINT projects_current_funding_check CHECK ((current_funding >= (0)::numeric)),
    CONSTRAINT projects_investment_period_check CHECK (((investment_period >= 6) AND (investment_period <= 120))),
    CONSTRAINT projects_min_investment_check CHECK ((min_investment >= (100)::numeric)),
    CONSTRAINT projects_minimum_funding_check CHECK ((minimum_funding >= (0)::numeric)),
    CONSTRAINT projects_raised_amount_check CHECK ((raised_amount >= (0)::numeric)),
    CONSTRAINT projects_risk_level_check CHECK (((risk_level)::text = ANY ((ARRAY['Low'::character varying, 'Medium'::character varying, 'High'::character varying])::text[]))),
    CONSTRAINT projects_target_amount_check CHECK ((target_amount >= (1000)::numeric))
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- TOC entry 3890 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.project_image_1; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.project_image_1 IS 'Primary project image URL from AWS S3';


--
-- TOC entry 3891 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.project_image_2; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.project_image_2 IS 'Secondary project image URL from AWS S3';


--
-- TOC entry 3892 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.project_image_3; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.project_image_3 IS 'Tertiary project image URL from AWS S3';


--
-- TOC entry 3893 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.min_investment; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.min_investment IS 'Minimum investment amount per investor';


--
-- TOC entry 3894 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.risk_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.risk_level IS 'Project risk level: Low, Medium, or High';


--
-- TOC entry 3895 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.investment_period; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.investment_period IS 'Investment period in months (6-120)';


--
-- TOC entry 3896 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.expected_return; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.expected_return IS 'Expected return percentage or description';


--
-- TOC entry 3897 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.start_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.start_date IS 'Project start date';


--
-- TOC entry 3898 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.end_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.end_date IS 'Project end date';


--
-- TOC entry 3899 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.target_amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.target_amount IS 'Target funding amount';


--
-- TOC entry 3900 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.raised_amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.raised_amount IS 'Current raised amount';


--
-- TOC entry 3901 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN projects.category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.category IS 'Project category (Agriculture, Technology, etc.)';


--
-- TOC entry 216 (class 1259 OID 17936)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    email character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    phone character varying(50),
    address text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    cooperative_id uuid,
    roles jsonb DEFAULT '["guest"]'::jsonb,
    kyc_status character varying(20) DEFAULT 'pending'::character varying,
    user_profile_image character varying(500),
    membership_payment_proof character varying(500)
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 3902 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN users.user_profile_image; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.user_profile_image IS 'User profile image URL from AWS S3';


--
-- TOC entry 3872 (class 0 OID 18153)
-- Dependencies: 224
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, entity_type, entity_id, operation, user_id, ip_address, user_agent, changes, old_values, new_values, reason, status, error_msg, created_at) FROM stdin;
\.


--
-- TOC entry 3866 (class 0 OID 17996)
-- Dependencies: 218
-- Data for Name: businesses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.businesses (id, name, business_type, description, owner_id, cooperative_id, registration_documents, approval_status, is_active, created_at, updated_at, business_image, registration_number, tax_id, legal_structure, industry, sector, address, phone, email, website, established_date, employee_count, annual_revenue, currency, bank_account, business_license, documents, status, approved_by, approved_at, rejection_reason, metadata, performance_metrics, compliance_status) FROM stdin;
768057bd-5049-4dbf-a92a-5d2da92b7fd3	Bisnis 1234	manufacturing	membuat furniture	ffcee1b1-019d-4105-8be8-790e0959074e	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-09-20 15:10:25.201224+07	2025-09-20 15:23:34.236283+07	\N	0101-PT-CAFE-0980947		PT	Manufactur		jalan abc	+628131313131	ryan.kharisma@outlook.com		2025-09-20	1	10000.00	IDR	2355563218	093-PT00284-CAFE09394	[]	draft	\N	\N	\N	null	null	null
1e96d0f6-e8fa-4535-8e93-26f129006672	warung sembako	retail	menjual berbagai macam sembako	7a5327fe-7ac2-45ff-8e9f-3a6a9f006f71	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-10-17 08:01:39.179318+07	2025-10-17 08:35:41.097772+07	\N	01234-CV-sembako-nila		UD	Makanan		bandung jawa barat	+6212323424536	demo-business@example.com	https://bisnis.co.id	2025-10-17	2	10000000.00	IDR	109875499834	UD-1234-NILA	[]	draft	\N	\N	\N	null	null	null
5bd816b6-8db5-4b55-ad5a-22a46937be7e	Toko Bunga Terakhir	agriculture	jualan bunga	a959b178-3cf7-4b42-a22e-986baae8a784	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-10-18 13:31:32.262846+07	2025-10-18 13:32:53.985643+07	\N	012-PT-123-bunga		PT	Agriculture		Jl. Wastukencana	+628113333333	user2@hajifund.id	https://bisnis.co.id	2025-10-18	19	150000000.00	IDR	1098754998341	PT-1234-5678-B	[]	draft	\N	\N	\N	null	null	null
3208430e-cfb6-4faa-b5e0-c95507bc4991	Test Toko Roti	retail	Jualan Roti nih bos.	9354b628-5c47-401e-84f4-a14a803ee9b0	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-10-11 13:22:03.035715+07	2025-10-18 15:35:37.888716+07	\N	012-PT-123		PT	Makanan		Jalan Roti	+628113333333	cobauser@gmail.com		2025-10-11	100	100000000.00	IDR	1098754998341	PT-1234-5678	[]	draft	\N	\N	\N	null	null	null
7ee97f32-581d-4a74-8303-22f1a6a6a70a	Test Business	technology	A test business for demo purposes	7a5327fe-7ac2-45ff-8e9f-3a6a9f006f71	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-10-05 10:43:47.03308+07	2025-10-18 15:54:18.917052+07	\N	TEST-002		PT	Software Development		Jl. Test Business No. 456, Jakarta	+62-123-456-789	test2@business.com	https://testbusiness2.com	2020-01-01	15	2000000000.00	IDR	1234567890	LIC-002	null	draft	\N	\N	\N	null	null	null
\.


--
-- TOC entry 3865 (class 0 OID 17952)
-- Dependencies: 217
-- Data for Name: cooperatives; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cooperatives (id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at, cooperative_image) FROM stdin;
57f24e40-31a3-4d64-b967-b8e12c6e6b21	Cooperative 2	COOP-2024-002-1000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-22 16:55:09.112004+07	2025-08-22 16:55:09.112004+07	\N
2f65f602-0788-4d55-bf38-a4f45eeb0d8f	Cooperative 6	COOP-2024-006-5000	Address 6	+12345670006	coop6@example.com	1234567896	{}	t	2025-08-22 16:55:09.118337+07	2025-08-22 16:55:09.118337+07	\N
bcd512df-6b8f-4fd6-889a-f32750bc8150	Cooperative 10	COOP-2024-010-5000	Address 10	+12345670010	coop10@example.com	12345678910	{}	t	2025-08-22 16:55:09.120838+07	2025-08-22 16:55:09.120838+07	\N
20eea354-26d6-43e5-bae4-6e97feef5caf	Cooperative 14	COOP-2024-014-1000	Address 14	+12345670014	coop14@example.com	12345678914	{}	t	2025-08-22 16:55:09.123934+07	2025-08-22 16:55:09.123934+07	\N
b882c945-dd67-481b-8417-e31121f29ceb	Cooperative 18	COOP-2024-018-7000	Address 18	+12345670018	coop18@example.com	12345678918	{}	t	2025-08-22 16:55:09.12678+07	2025-08-22 16:55:09.12678+07	\N
9f4c8f09-0409-400a-b635-b456f7ce6280	Cooperative 2	COOP-2024-002-2000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-22 16:55:46.026764+07	2025-08-22 16:55:46.026764+07	\N
353e0df7-ef7b-41e3-b333-e9d54b3d647d	Cooperative 2	COOP-2024-002-1755856577350905000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-22 16:56:17.350912+07	2025-08-22 16:56:17.350912+07	\N
d27edc46-3e48-43f7-a427-141b59b37429	Cooperative 6	COOP-2024-006-1755856577353861000	Address 6	+12345670006	coop6@example.com	1234567896	{}	t	2025-08-22 16:56:17.353868+07	2025-08-22 16:56:17.353869+07	\N
0141f6db-7a8e-48eb-82e8-ff2153cd2b3c	Cooperative 10	COOP-2024-010-1755856577359731000	Address 10	+12345670010	coop10@example.com	12345678910	{}	t	2025-08-22 16:56:17.359733+07	2025-08-22 16:56:17.359733+07	\N
367f6457-0d86-438f-90c1-d82ebcbe3990	Cooperative 14	COOP-2024-014-1755856577362902000	Address 14	+12345670014	coop14@example.com	12345678914	{}	t	2025-08-22 16:56:17.362907+07	2025-08-22 16:56:17.362907+07	\N
9f3c1ab8-13e9-45e7-bcb9-96449ea68424	Cooperative 18	COOP-2024-018-1755856577365424000	Address 18	+12345670018	coop18@example.com	12345678918	{}	t	2025-08-22 16:56:17.365426+07	2025-08-22 16:56:17.365426+07	\N
cf5f14d5-75ca-4d5f-908e-3473459e6e4c	Cooperative 2	COOP-2024-002-1755858945246164000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-22 17:35:45.246167+07	2025-08-22 17:35:45.246167+07	\N
90198244-9a6d-4949-8997-143947f6a306	Cooperative 6	COOP-2024-006-1755858945249031000	Address 6	+12345670006	coop6@example.com	1234567896	{}	t	2025-08-22 17:35:45.249033+07	2025-08-22 17:35:45.249033+07	\N
072d8881-c9c8-46dc-b5f7-82f6ac313882	Cooperative 10	COOP-2024-010-1755858945250550000	Address 10	+12345670010	coop10@example.com	12345678910	{}	t	2025-08-22 17:35:45.250551+07	2025-08-22 17:35:45.250551+07	\N
b0ed72d3-cd9b-43c5-94a1-206af8a61cf5	Cooperative 14	COOP-2024-014-1755858945251896000	Address 14	+12345670014	coop14@example.com	12345678914	{}	t	2025-08-22 17:35:45.251898+07	2025-08-22 17:35:45.251898+07	\N
540cd8fe-6281-4474-a55b-773ee075afb7	Cooperative 18	COOP-2024-018-1755858945253538000	Address 18	+12345670018	coop18@example.com	12345678918	{}	t	2025-08-22 17:35:45.253541+07	2025-08-22 17:35:45.253541+07	\N
8231a6c4-6f34-4f27-8b1f-0185c69107bd	Cooperative 2	COOP-2024-002-1756473775214162000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-29 20:22:55.214165+07	2025-08-29 20:22:55.214165+07	\N
47c14783-37f8-4e3c-8d53-66242310663b	Cooperative 6	COOP-2024-006-1756473775217935000	Address 6	+12345670006	coop6@example.com	1234567896	{}	t	2025-08-29 20:22:55.217938+07	2025-08-29 20:22:55.217938+07	\N
e41aa90c-7ba4-46d1-ad01-d8f962d8f3ec	Cooperative 10	COOP-2024-010-1756473775220458000	Address 10	+12345670010	coop10@example.com	12345678910	{}	t	2025-08-29 20:22:55.220461+07	2025-08-29 20:22:55.220461+07	\N
2feb78a4-b0aa-409e-aa7c-2d5b213ec764	Cooperative 14	COOP-2024-014-1756473775222575000	Address 14	+12345670014	coop14@example.com	12345678914	{}	t	2025-08-29 20:22:55.222577+07	2025-08-29 20:22:55.222577+07	\N
a928114a-4841-412d-baae-b6afbe4d791b	Cooperative 18	COOP-2024-018-1756473775224148000	Address 18	+12345670018	coop18@example.com	12345678918	{}	t	2025-08-29 20:22:55.22415+07	2025-08-29 20:22:55.22415+07	\N
c4122ef5-c0c4-4b3a-ba26-9dbcf39f58f1	Cooperative 2	COOP-2024-002-1756475953203992000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-29 20:59:13.204+07	2025-08-29 20:59:13.204+07	\N
2ede562a-f74d-4248-ab02-97ba80026b35	Cooperative 6	COOP-2024-006-1756475953210519000	Address 6	+12345670006	coop6@example.com	1234567896	{}	t	2025-08-29 20:59:13.210522+07	2025-08-29 20:59:13.210522+07	\N
54af08c6-d52a-4e4d-af03-51dcef5010e7	Cooperative 10	COOP-2024-010-1756475953213462000	Address 10	+12345670010	coop10@example.com	12345678910	{}	t	2025-08-29 20:59:13.213464+07	2025-08-29 20:59:13.213464+07	\N
e4d91a3c-bbe0-4c11-aa61-026a3c9cd25a	Cooperative 14	COOP-2024-014-1756475953215304000	Address 14	+12345670014	coop14@example.com	12345678914	{}	t	2025-08-29 20:59:13.215306+07	2025-08-29 20:59:13.215306+07	\N
3862fc1e-832d-4326-8bd9-4b5654af13af	Cooperative 18	COOP-2024-018-1756475953216849000	Address 18	+12345670018	coop18@example.com	12345678918	{}	t	2025-08-29 20:59:13.216851+07	2025-08-29 20:59:13.216851+07	\N
e3b7e0e8-0833-496e-92e4-c0a38fd1c2aa	Cooperative 2	COOP-2024-002-1756479580173371000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-29 21:59:40.17338+07	2025-08-29 21:59:40.17338+07	\N
c6358183-4917-4032-baa7-72a3b9abfa72	Cooperative 6	COOP-2024-006-1756479580189771000	Address 6	+12345670006	coop6@example.com	1234567896	{}	t	2025-08-29 21:59:40.189776+07	2025-08-29 21:59:40.189777+07	\N
c72031bf-b80c-4bbf-aba9-72c3d8ea4547	Cooperative 10	COOP-2024-010-1756479580204602000	Address 10	+12345670010	coop10@example.com	12345678910	{}	t	2025-08-29 21:59:40.204607+07	2025-08-29 21:59:40.204607+07	\N
b99d6f7c-06fd-4e7e-ad4c-8338ff4b34ac	Cooperative 14	COOP-2024-014-1756479580248658000	Address 14	+12345670014	coop14@example.com	12345678914	{}	t	2025-08-29 21:59:40.248663+07	2025-08-29 21:59:40.248663+07	\N
91eb5844-2926-47bf-8533-3c9e5b2bc6c1	Cooperative 18	COOP-2024-018-1756479580252200000	Address 18	+12345670018	coop18@example.com	12345678918	{}	t	2025-08-29 21:59:40.252204+07	2025-08-29 21:59:40.252204+07	\N
97be9505-05f8-4ff0-adac-8ab71af2ffb8	Cooperative 2	COOP-2024-002-1756479720903058000	Address 2	+12345670002	coop2@example.com	1234567892	{}	t	2025-08-29 22:02:00.90306+07	2025-08-29 22:02:00.90306+07	\N
d696e4c7-7aeb-4d18-a952-d7b28800d723	Cooperative 6	COOP-2024-006-1756479720905615000	Address 6	+12345670006	coop6@example.com	1234567896	{}	t	2025-08-29 22:02:00.905617+07	2025-08-29 22:02:00.905617+07	\N
50ff5405-f27e-4eeb-a625-41888f96aed3	Cooperative 10	COOP-2024-010-1756479720907980000	Address 10	+12345670010	coop10@example.com	12345678910	{}	t	2025-08-29 22:02:00.907984+07	2025-08-29 22:02:00.907984+07	\N
4b1869f6-c172-48ef-8dad-b23a57979bef	Cooperative 14	COOP-2024-014-1756479720909962000	Address 14	+12345670014	coop14@example.com	12345678914	{}	t	2025-08-29 22:02:00.909964+07	2025-08-29 22:02:00.909964+07	\N
36794e8e-e083-4ba5-94b5-c1ca0df27a32	Cooperative 18	COOP-2024-018-1756479720911601000	Address 18	+12345670018	coop18@example.com	12345678918	{}	t	2025-08-29 22:02:00.911603+07	2025-08-29 22:02:00.911603+07	\N
550e8400-e29b-41d4-a716-446655440001	Koperasi Haji	KH-001-2024	Jl. Masjidil Haram No. 123, Jakarta Pusat	+62-21-12345678	info@koperasihaji.id	1234567890	{"platform_fee": 5, "default_business_share": 30, "default_investor_share": 70}	t	2025-09-19 19:44:43.812393+07	2025-09-19 21:37:14.980121+07	\N
550e8400-e29b-41d4-a716-446655440002	Koperasi SIDANA	SIDANA-002-2024	Jl. Simpan Pinjam No. 456, Jakarta Selatan	+62-21-87654321	info@koperasisidana.id	0987654321	{"platform_fee": 3, "default_business_share": 25, "default_investor_share": 75}	t	2025-09-19 19:44:43.812393+07	2025-09-19 21:37:14.980121+07	\N
\.


--
-- TOC entry 3874 (class 0 OID 24752)
-- Dependencies: 226
-- Data for Name: idempotency_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.idempotency_keys (id, user_id, endpoint, request_hash, response_data, status, created_at, expires_at, sequence_number, table_name, random_suffix) FROM stdin;
\.


--
-- TOC entry 3873 (class 0 OID 24738)
-- Dependencies: 225
-- Data for Name: images; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.images (id, image_url, image_name, used_by, image_size, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3871 (class 0 OID 18114)
-- Dependencies: 223
-- Data for Name: investment_returns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.investment_returns (id, investment_id, distribution_id, return_amount, return_percentage, payment_date, status, transaction_ref, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3869 (class 0 OID 18062)
-- Dependencies: 221
-- Data for Name: investments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.investments (id, project_id, investor_id, amount, investment_date, profit_sharing_percentage, status, transaction_ref, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3870 (class 0 OID 18097)
-- Dependencies: 222
-- Data for Name: profit_distributions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profit_distributions (id, project_id, business_profit, distribution_date, total_distributed, status, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3867 (class 0 OID 18027)
-- Dependencies: 219
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, title, description, business_id, funding_goal, minimum_funding, current_funding, funding_deadline, profit_sharing_ratio, project_type, status, milestones, documents, created_at, updated_at, project_image_1, project_image_2, project_image_3, min_investment, risk_level, investment_period, expected_return, start_date, end_date, target_amount, raised_amount, category, owner_id, cooperative_id, approved_by, approved_at, approval_status, rejected_by, rejected_at, rejection_reason, reviewer_comments, sharia_compliant) FROM stdin;
d9088888-f633-4019-9fb5-ea671db5ef03	Toko Baru Bunga	cabang baru	5bd816b6-8db5-4b55-ad5a-22a46937be7e	\N	\N	0.00	\N	{"business": 30, "investor": 70}	expansion	approved	[]	{}	2025-10-18 13:37:07.52503+07	2025-10-18 15:47:02.519841+07	\N	\N	\N	1000000.00	Low	12	15	\N	\N	200000000.00	0.00	\N	a959b178-3cf7-4b42-a22e-986baae8a784	00000000-0000-0000-0000-000000000000	123e4567-e89b-12d3-a456-426614174004	2025-10-18 15:46:45.73399+07	approved	\N	\N	\N	Testing status fix	t
\.


--
-- TOC entry 3864 (class 0 OID 17936)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (email, name, password, phone, address, is_active, created_at, updated_at, id, cooperative_id, roles, kyc_status, user_profile_image, membership_payment_proof) FROM stdin;
user-1-36dee635@example.com	User 1	hashedpassword	\N	\N	t	2025-08-22 16:55:09.034328+07	2025-08-22 16:55:09.034328+07	36dee635-5d28-43cd-ba4a-3cc52ae3b571	\N	["guest"]	pending	\N	\N
user-6-77987356@example.com	User 6	hashedpassword	\N	\N	t	2025-08-22 16:55:09.048143+07	2025-08-22 16:55:09.048143+07	77987356-c2f9-49b3-90d3-b63a4fb194d0	\N	["guest"]	pending	\N	\N
user-14-e84f8dd7@example.com	User 14	hashedpassword	\N	\N	t	2025-08-22 16:55:09.05353+07	2025-08-22 16:55:09.05353+07	e84f8dd7-2c47-44eb-94b8-ddc4c93180a4	\N	["guest"]	pending	\N	\N
user-15-53990c74@example.com	User 15	hashedpassword	\N	\N	t	2025-08-22 16:55:09.054075+07	2025-08-22 16:55:09.054075+07	53990c74-a2ea-4e9d-8d1b-b30783f69e62	\N	["guest"]	pending	\N	\N
user-16-3966c8fc@example.com	User 16	hashedpassword	\N	\N	t	2025-08-22 16:55:09.0547+07	2025-08-22 16:55:09.0547+07	3966c8fc-2ce7-4e1f-911a-119777fd8ad2	\N	["guest"]	pending	\N	\N
user-17-6d92cf69@example.com	User 17	hashedpassword	\N	\N	t	2025-08-22 16:55:09.055198+07	2025-08-22 16:55:09.055198+07	6d92cf69-b64d-4399-a255-a9385c915ba6	\N	["guest"]	pending	\N	\N
user-18-1fdd29d6@example.com	User 18	hashedpassword	\N	\N	t	2025-08-22 16:55:09.056044+07	2025-08-22 16:55:09.056045+07	1fdd29d6-2108-47b2-aa20-ad6171481602	\N	["guest"]	pending	\N	\N
user-22-4189952a@example.com	User 22	hashedpassword	\N	\N	t	2025-08-22 16:55:09.059832+07	2025-08-22 16:55:09.059832+07	4189952a-a96b-4937-9209-fe6ffa063a0b	\N	["guest"]	pending	\N	\N
user-29-54f65c76@example.com	User 29	hashedpassword	\N	\N	t	2025-08-22 16:55:09.063765+07	2025-08-22 16:55:09.063766+07	54f65c76-a92f-4ec4-a890-dc1d59c5700d	\N	["guest"]	pending	\N	\N
user-32-1c48efad@example.com	User 32	hashedpassword	\N	\N	t	2025-08-22 16:55:09.06554+07	2025-08-22 16:55:09.06554+07	1c48efad-8a84-442f-a48d-cde23583a4af	\N	["guest"]	pending	\N	\N
user-34-693b1f6d@example.com	User 34	hashedpassword	\N	\N	t	2025-08-22 16:55:09.066819+07	2025-08-22 16:55:09.066819+07	693b1f6d-c3f0-4df3-ab54-d58c24556c32	\N	["guest"]	pending	\N	\N
user-35-e9b42063@example.com	User 35	hashedpassword	\N	\N	t	2025-08-22 16:55:09.067536+07	2025-08-22 16:55:09.067536+07	e9b42063-c6e5-4d42-b492-7f6ae5a0e2b2	\N	["guest"]	pending	\N	\N
user-39-879441d5@example.com	User 39	hashedpassword	\N	\N	t	2025-08-22 16:55:09.070308+07	2025-08-22 16:55:09.070309+07	879441d5-3843-4b60-9f53-202e6330a977	\N	["guest"]	pending	\N	\N
user-41-19ddcf12@example.com	User 41	hashedpassword	\N	\N	t	2025-08-22 16:55:09.072099+07	2025-08-22 16:55:09.072099+07	19ddcf12-64c6-4a2e-ad24-953c7861450b	\N	["guest"]	pending	\N	\N
user-47-f383570a@example.com	User 47	hashedpassword	\N	\N	t	2025-08-22 16:55:09.076919+07	2025-08-22 16:55:09.076919+07	f383570a-6c59-4112-b72d-bfd3f937cefb	\N	["guest"]	pending	\N	\N
user-58-626847d1@example.com	User 58	hashedpassword	\N	\N	t	2025-08-22 16:55:09.083214+07	2025-08-22 16:55:09.083214+07	626847d1-5443-44a5-820d-ecd9a61ab3f5	\N	["guest"]	pending	\N	\N
user-59-9ce1b214@example.com	User 59	hashedpassword	\N	\N	t	2025-08-22 16:55:09.083594+07	2025-08-22 16:55:09.083594+07	9ce1b214-ce1b-4263-b9ae-49c2778cb9b7	\N	["guest"]	pending	\N	\N
user-65-f5fc5e9c@example.com	User 65	hashedpassword	\N	\N	t	2025-08-22 16:55:09.085786+07	2025-08-22 16:55:09.085786+07	f5fc5e9c-943c-46c1-a25d-ceedc539830f	\N	["guest"]	pending	\N	\N
user-71-e40c2f8f@example.com	User 71	hashedpassword	\N	\N	t	2025-08-22 16:55:09.088074+07	2025-08-22 16:55:09.088074+07	e40c2f8f-e7d3-430d-9f43-01596f6efe43	\N	["guest"]	pending	\N	\N
user-75-f76a02be@example.com	User 75	hashedpassword	\N	\N	t	2025-08-22 16:55:09.091764+07	2025-08-22 16:55:09.091764+07	f76a02be-d792-4292-98e9-1a54d2c3a9c1	\N	["guest"]	pending	\N	\N
user-81-07936ebc@example.com	User 81	hashedpassword	\N	\N	t	2025-08-22 16:55:09.095069+07	2025-08-22 16:55:09.095069+07	07936ebc-c102-4ca0-b064-a221d1c812b3	\N	["guest"]	pending	\N	\N
user-83-28b24200@example.com	User 83	hashedpassword	\N	\N	t	2025-08-22 16:55:09.096191+07	2025-08-22 16:55:09.096191+07	28b24200-a0c3-4d66-82e8-06197f0a4d97	\N	["guest"]	pending	\N	\N
user-89-bc825aea@example.com	User 89	hashedpassword	\N	\N	t	2025-08-22 16:55:09.099694+07	2025-08-22 16:55:09.099694+07	bc825aea-027c-4cbd-b9ad-86a83e70d38c	\N	["guest"]	pending	\N	\N
user-90-b54d3f9f@example.com	User 90	hashedpassword	\N	\N	t	2025-08-22 16:55:09.100532+07	2025-08-22 16:55:09.100532+07	b54d3f9f-bfd6-4489-b274-c402fab30425	\N	["guest"]	pending	\N	\N
user-93-fe78258b@example.com	User 93	hashedpassword	\N	\N	t	2025-08-22 16:55:09.101978+07	2025-08-22 16:55:09.101978+07	fe78258b-e326-4a97-8e4f-3301f458aa05	\N	["guest"]	pending	\N	\N
user-95-32fa0b38@example.com	User 95	hashedpassword	\N	\N	t	2025-08-22 16:55:09.102812+07	2025-08-22 16:55:09.102812+07	32fa0b38-88cd-4c13-9b32-f877296a0b59	\N	["guest"]	pending	\N	\N
user-98-c2b5a739@example.com	User 98	hashedpassword	\N	\N	t	2025-08-22 16:55:09.104225+07	2025-08-22 16:55:09.104225+07	c2b5a739-29b9-4c63-9c34-415c1b545c6e	\N	["guest"]	pending	\N	\N
concurrent-user-2-5e1637d4@example.com	Concurrent User 2	password	\N	\N	t	2025-08-22 16:55:09.326159+07	2025-08-22 16:55:09.32616+07	5e1637d4-ee6e-4cd2-aac1-74e7bea78238	\N	["guest"]	pending	\N	\N
perf-test-0-a040ffac@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:09.530069+07	2025-08-22 16:55:09.530069+07	a040ffac-787a-4b77-a9aa-41e39c523111	\N	["guest"]	pending	\N	\N
perf-test-1-571eb385@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:09.530698+07	2025-08-22 16:55:09.530699+07	571eb385-25cb-4fbe-8957-92430bbb770a	\N	["guest"]	pending	\N	\N
perf-test-2-e50a2782@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:09.531159+07	2025-08-22 16:55:09.53116+07	e50a2782-8bc6-4bf0-8585-0bf83551c5f6	\N	["guest"]	pending	\N	\N
perf-test-3-45438d86@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:09.531631+07	2025-08-22 16:55:09.531631+07	45438d86-c69c-4d15-99cc-2e91864f1588	\N	["guest"]	pending	\N	\N
perf-test-4-f85db3ac@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:09.532146+07	2025-08-22 16:55:09.532146+07	f85db3ac-82cb-4a9d-a6d4-f17cd1987924	\N	["guest"]	pending	\N	\N
perf-test-5-b8750bdb@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:09.532627+07	2025-08-22 16:55:09.532627+07	b8750bdb-361e-452a-abbc-e02c5470aaaa	\N	["guest"]	pending	\N	\N
perf-test-6-c6fa5e93@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:09.533096+07	2025-08-22 16:55:09.533096+07	c6fa5e93-c451-4b37-81d3-8497c4c71c04	\N	["guest"]	pending	\N	\N
perf-test-7-4980c800@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:09.533656+07	2025-08-22 16:55:09.533656+07	4980c800-71b3-4659-8120-bf1789746068	\N	["guest"]	pending	\N	\N
perf-test-8-124d324c@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:09.534158+07	2025-08-22 16:55:09.534159+07	124d324c-cd10-4ace-b5fe-6b3a90978920	\N	["guest"]	pending	\N	\N
perf-test-9-3756da06@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:09.534575+07	2025-08-22 16:55:09.534575+07	3756da06-3cf2-42a5-89f6-d7ee55a0c413	\N	["guest"]	pending	\N	\N
perf-test-10-ff6f4371@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:09.53495+07	2025-08-22 16:55:09.53495+07	ff6f4371-cc64-4cdf-8697-046d234c9581	\N	["guest"]	pending	\N	\N
perf-test-11-e23dc825@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:09.535324+07	2025-08-22 16:55:09.535324+07	e23dc825-9985-4260-8fda-735661c6aa72	\N	["guest"]	pending	\N	\N
perf-test-12-4df5425b@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:09.535687+07	2025-08-22 16:55:09.535687+07	4df5425b-3270-41bb-9e77-2bc47d296219	\N	["guest"]	pending	\N	\N
perf-test-13-2f08fcbc@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:09.536064+07	2025-08-22 16:55:09.536064+07	2f08fcbc-22d4-4d3e-aeb2-e42664001605	\N	["guest"]	pending	\N	\N
perf-test-14-e01a8081@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:09.536427+07	2025-08-22 16:55:09.536427+07	e01a8081-34eb-41b7-8c26-c45544d6d5bf	\N	["guest"]	pending	\N	\N
perf-test-15-846dd8ce@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:09.536885+07	2025-08-22 16:55:09.536885+07	846dd8ce-ed5c-4246-bdb9-6bdd7a447607	\N	["guest"]	pending	\N	\N
perf-test-16-f831321a@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:09.537271+07	2025-08-22 16:55:09.537271+07	f831321a-dac8-42d9-8aea-941901c1fc1c	\N	["guest"]	pending	\N	\N
perf-test-17-9f57f7af@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:09.537754+07	2025-08-22 16:55:09.537754+07	9f57f7af-d2fd-4802-864f-e1445807b3a3	\N	["guest"]	pending	\N	\N
perf-test-18-90b033b3@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:09.538234+07	2025-08-22 16:55:09.538234+07	90b033b3-a99a-422f-908e-b4ce08b6d1e8	\N	["guest"]	pending	\N	\N
perf-test-19-d7337aa4@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:09.539731+07	2025-08-22 16:55:09.539731+07	d7337aa4-0af9-4d85-8347-69a025dfe6b3	\N	["guest"]	pending	\N	\N
perf-test-20-27dac73b@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:09.540639+07	2025-08-22 16:55:09.540639+07	27dac73b-99c3-435f-b2a4-b5161b64a1db	\N	["guest"]	pending	\N	\N
perf-test-21-888dcdd5@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:09.541248+07	2025-08-22 16:55:09.541248+07	888dcdd5-1fad-42ba-ab15-80a763e9820c	\N	["guest"]	pending	\N	\N
perf-test-22-97182af7@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:09.541798+07	2025-08-22 16:55:09.541798+07	97182af7-7ee6-47b5-ae68-5372b3d8bc5b	\N	["guest"]	pending	\N	\N
perf-test-23-f975b09a@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:09.542312+07	2025-08-22 16:55:09.542312+07	f975b09a-1933-4999-8b16-c2e89696c66a	\N	["guest"]	pending	\N	\N
perf-test-24-cdb09ae1@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:09.542838+07	2025-08-22 16:55:09.542838+07	cdb09ae1-0a18-4522-8727-a97fdd473ec6	\N	["guest"]	pending	\N	\N
perf-test-25-20df7a77@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:09.543257+07	2025-08-22 16:55:09.543258+07	20df7a77-a360-4e2c-aab7-827dec29d157	\N	["guest"]	pending	\N	\N
perf-test-26-0a1071cd@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:09.543983+07	2025-08-22 16:55:09.543983+07	0a1071cd-a6bf-47a9-8317-6bd265bf7174	\N	["guest"]	pending	\N	\N
perf-test-27-efc0fe24@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:09.544416+07	2025-08-22 16:55:09.544416+07	efc0fe24-5ca3-4e5f-966f-c8e1d0975ef2	\N	["guest"]	pending	\N	\N
perf-test-28-a85f27d7@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:09.544809+07	2025-08-22 16:55:09.544809+07	a85f27d7-2ae2-41a3-80b1-1fdc19aad2fb	\N	["guest"]	pending	\N	\N
perf-test-29-290b2581@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:09.545251+07	2025-08-22 16:55:09.545251+07	290b2581-d4e0-40a6-9c66-4462b6de5f60	\N	["guest"]	pending	\N	\N
perf-test-30-7b471d2c@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:09.545775+07	2025-08-22 16:55:09.545776+07	7b471d2c-10cd-4847-99e6-36b76c649579	\N	["guest"]	pending	\N	\N
perf-test-31-03760b51@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:09.546236+07	2025-08-22 16:55:09.546236+07	03760b51-537b-4222-b098-cc5cd4bcf4cf	\N	["guest"]	pending	\N	\N
perf-test-32-0a5a3a5c@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:09.546684+07	2025-08-22 16:55:09.546684+07	0a5a3a5c-0cec-4a73-9659-fcf02d7ad80f	\N	["guest"]	pending	\N	\N
perf-test-33-26f120ac@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:09.547217+07	2025-08-22 16:55:09.547218+07	26f120ac-f1b4-443c-a90d-9d3909ff10b7	\N	["guest"]	pending	\N	\N
perf-test-34-23104393@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:09.547753+07	2025-08-22 16:55:09.547753+07	23104393-ca4c-4d1f-94f8-75fa66bcc200	\N	["guest"]	pending	\N	\N
perf-test-35-3de065af@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:09.548191+07	2025-08-22 16:55:09.548191+07	3de065af-0c3f-47ea-ab4f-8be97b05c742	\N	["guest"]	pending	\N	\N
perf-test-36-d09974a0@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:09.548732+07	2025-08-22 16:55:09.548732+07	d09974a0-3652-444b-82ce-fb4a5409ca36	\N	["guest"]	pending	\N	\N
perf-test-37-fa9fe435@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:09.54922+07	2025-08-22 16:55:09.54922+07	fa9fe435-023c-4727-94d7-64320b482736	\N	["guest"]	pending	\N	\N
perf-test-38-d2091f58@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:09.549838+07	2025-08-22 16:55:09.549838+07	d2091f58-86f7-4619-8967-51198614ac63	\N	["guest"]	pending	\N	\N
perf-test-39-11fff901@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:09.550599+07	2025-08-22 16:55:09.550599+07	11fff901-0124-4da6-aff6-2b5f2465dded	\N	["guest"]	pending	\N	\N
perf-test-40-01043821@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:09.551241+07	2025-08-22 16:55:09.551241+07	01043821-7441-4e00-9bec-7a084b72844e	\N	["guest"]	pending	\N	\N
perf-test-41-5bc99927@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:09.551747+07	2025-08-22 16:55:09.551747+07	5bc99927-cf67-421d-98b7-1be3055cd1b0	\N	["guest"]	pending	\N	\N
perf-test-42-861adcee@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:09.552246+07	2025-08-22 16:55:09.552246+07	861adcee-8a56-49cf-ab20-72c80f8a7b6d	\N	["guest"]	pending	\N	\N
perf-test-43-5d1ae615@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:09.552722+07	2025-08-22 16:55:09.552722+07	5d1ae615-b0fb-4cc8-98ce-3cf06eb68965	\N	["guest"]	pending	\N	\N
perf-test-44-a80e5be4@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:09.553143+07	2025-08-22 16:55:09.553144+07	a80e5be4-c513-4e4f-95a0-adde96b098ff	\N	["guest"]	pending	\N	\N
perf-test-45-ebc64453@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:09.553637+07	2025-08-22 16:55:09.553637+07	ebc64453-e434-43c3-82c5-958241e51371	\N	["guest"]	pending	\N	\N
perf-test-46-65240787@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:09.554189+07	2025-08-22 16:55:09.554189+07	65240787-cb42-4a77-852a-fae64fc50951	\N	["guest"]	pending	\N	\N
perf-test-47-523fc54a@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:09.554782+07	2025-08-22 16:55:09.554782+07	523fc54a-a58e-4a4c-8bfb-4ec4641d3ae5	\N	["guest"]	pending	\N	\N
perf-test-48-c437a5bc@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:09.555919+07	2025-08-22 16:55:09.555919+07	c437a5bc-8949-4c2d-92a4-42b28194a755	\N	["guest"]	pending	\N	\N
perf-test-49-a57c3f06@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:09.557672+07	2025-08-22 16:55:09.557673+07	a57c3f06-5f15-43a5-9f8d-44ad04905a32	\N	["guest"]	pending	\N	\N
user-0-17b8a81f@example.com	User 0	hashedpassword	\N	\N	t	2025-08-22 16:55:45.956342+07	2025-08-22 16:55:45.956343+07	17b8a81f-e3d2-4b25-8dbe-5a5b2afff913	\N	["guest"]	pending	\N	\N
user-1-51cfd100@example.com	User 1	hashedpassword	\N	\N	t	2025-08-22 16:55:45.959046+07	2025-08-22 16:55:45.959047+07	51cfd100-87b2-4ea1-b7aa-6c7bf9f45c16	\N	["guest"]	pending	\N	\N
user-2-acca37f2@example.com	User 2	hashedpassword	\N	\N	t	2025-08-22 16:55:45.959627+07	2025-08-22 16:55:45.959628+07	acca37f2-b2de-4510-9b2d-343618fbf003	\N	["guest"]	pending	\N	\N
user-8-53cf1e11@example.com	User 8	hashedpassword	\N	\N	t	2025-08-22 16:55:45.970663+07	2025-08-22 16:55:45.970663+07	53cf1e11-9c8f-4468-95bf-4e517b2a8aee	\N	["guest"]	pending	\N	\N
user-13-84d29cec@example.com	User 13	hashedpassword	\N	\N	t	2025-08-22 16:55:45.974049+07	2025-08-22 16:55:45.97405+07	84d29cec-c10d-47c3-be9a-4d7a1b3794ef	\N	["guest"]	pending	\N	\N
user-17-bad2f7ae@example.com	User 17	hashedpassword	\N	\N	t	2025-08-22 16:55:45.975937+07	2025-08-22 16:55:45.975937+07	bad2f7ae-c0fc-44b1-bc73-dd328a45332e	\N	["guest"]	pending	\N	\N
user-24-dd082d0e@example.com	User 24	hashedpassword	\N	\N	t	2025-08-22 16:55:45.97857+07	2025-08-22 16:55:45.97857+07	dd082d0e-8891-4100-a112-d42d1ca0c4ac	\N	["guest"]	pending	\N	\N
user-28-09797025@example.com	User 28	hashedpassword	\N	\N	t	2025-08-22 16:55:45.981925+07	2025-08-22 16:55:45.981925+07	09797025-ac5e-4cb1-a17f-7075744fdd7d	\N	["guest"]	pending	\N	\N
user-30-a4befacc@example.com	User 30	hashedpassword	\N	\N	t	2025-08-22 16:55:45.984004+07	2025-08-22 16:55:45.984004+07	a4befacc-655e-4893-a90e-b1a17de17895	\N	["guest"]	pending	\N	\N
user-31-860ba9cb@example.com	User 31	hashedpassword	\N	\N	t	2025-08-22 16:55:45.984966+07	2025-08-22 16:55:45.984966+07	860ba9cb-063b-4709-bb03-4380b7e20bd7	\N	["guest"]	pending	\N	\N
user-33-5cdb738b@example.com	User 33	hashedpassword	\N	\N	t	2025-08-22 16:55:45.985981+07	2025-08-22 16:55:45.985981+07	5cdb738b-d04c-42c6-9b38-14ad6b9e45bb	\N	["guest"]	pending	\N	\N
user-34-143eb02a@example.com	User 34	hashedpassword	\N	\N	t	2025-08-22 16:55:45.986613+07	2025-08-22 16:55:45.986613+07	143eb02a-63c8-46d3-9a5a-93a78c82e6b8	\N	["guest"]	pending	\N	\N
user-35-c645b13b@example.com	User 35	hashedpassword	\N	\N	t	2025-08-22 16:55:45.987192+07	2025-08-22 16:55:45.987192+07	c645b13b-aa4b-470c-8509-e5fdf0f75cb8	\N	["guest"]	pending	\N	\N
user-37-7b39bf8a@example.com	User 37	hashedpassword	\N	\N	t	2025-08-22 16:55:45.988277+07	2025-08-22 16:55:45.988277+07	7b39bf8a-0b60-4e41-b1da-d24dc40c8e0b	\N	["guest"]	pending	\N	\N
user-43-b8892abc@example.com	User 43	hashedpassword	\N	\N	t	2025-08-22 16:55:45.990948+07	2025-08-22 16:55:45.990948+07	b8892abc-5bab-445f-90f9-ed5627072bb1	\N	["guest"]	pending	\N	\N
user-47-685ede74@example.com	User 47	hashedpassword	\N	\N	t	2025-08-22 16:55:45.993427+07	2025-08-22 16:55:45.993427+07	685ede74-5abe-45f7-845f-a1eb40339424	\N	["guest"]	pending	\N	\N
user-53-3429a312@example.com	User 53	hashedpassword	\N	\N	t	2025-08-22 16:55:45.995788+07	2025-08-22 16:55:45.995788+07	3429a312-6e7d-4fd7-ae13-33e993885568	\N	["guest"]	pending	\N	\N
user-60-f5b0679d@example.com	User 60	hashedpassword	\N	\N	t	2025-08-22 16:55:46.001349+07	2025-08-22 16:55:46.001349+07	f5b0679d-20df-456f-bf14-db25a56f98e3	\N	["guest"]	pending	\N	\N
user-63-964c1c90@example.com	User 63	hashedpassword	\N	\N	t	2025-08-22 16:55:46.003104+07	2025-08-22 16:55:46.003104+07	964c1c90-3286-4d07-a979-de09327918a4	\N	["guest"]	pending	\N	\N
user-65-e5a03ee6@example.com	User 65	hashedpassword	\N	\N	t	2025-08-22 16:55:46.004434+07	2025-08-22 16:55:46.004434+07	e5a03ee6-3bfb-4bad-b4ed-1f42f04572fa	\N	["guest"]	pending	\N	\N
user-66-0416791d@example.com	User 66	hashedpassword	\N	\N	t	2025-08-22 16:55:46.00509+07	2025-08-22 16:55:46.005091+07	0416791d-d9a8-419a-ba7e-c7253a56efb1	\N	["guest"]	pending	\N	\N
user-71-21a892f8@example.com	User 71	hashedpassword	\N	\N	t	2025-08-22 16:55:46.007741+07	2025-08-22 16:55:46.007742+07	21a892f8-811e-4789-8f8f-9498a6350e5d	\N	["guest"]	pending	\N	\N
user-77-2ab4141c@example.com	User 77	hashedpassword	\N	\N	t	2025-08-22 16:55:46.010321+07	2025-08-22 16:55:46.010321+07	2ab4141c-b92a-464f-95e5-6c854e7699aa	\N	["guest"]	pending	\N	\N
user-79-5bab0b68@example.com	User 79	hashedpassword	\N	\N	t	2025-08-22 16:55:46.011223+07	2025-08-22 16:55:46.011224+07	5bab0b68-bd5a-49d4-a371-1edc7d8aaf7b	\N	["guest"]	pending	\N	\N
user-83-8a7f555f@example.com	User 83	hashedpassword	\N	\N	t	2025-08-22 16:55:46.013361+07	2025-08-22 16:55:46.013361+07	8a7f555f-603c-4d68-9202-2f9908f9b0d5	\N	["guest"]	pending	\N	\N
user-87-38c1cb4b@example.com	User 87	hashedpassword	\N	\N	t	2025-08-22 16:55:46.01831+07	2025-08-22 16:55:46.01831+07	38c1cb4b-eab0-4069-8424-cd69b61b8996	\N	["guest"]	pending	\N	\N
user-88-61004efd@example.com	User 88	hashedpassword	\N	\N	t	2025-08-22 16:55:46.018855+07	2025-08-22 16:55:46.018855+07	61004efd-2f9d-4a7e-a0e7-65148a3ebdc9	\N	["guest"]	pending	\N	\N
user-91-97381f20@example.com	User 91	hashedpassword	\N	\N	t	2025-08-22 16:55:46.020745+07	2025-08-22 16:55:46.020745+07	97381f20-a747-4453-bad7-b54048029d48	\N	["guest"]	pending	\N	\N
user-95-6b3a01be@example.com	User 95	hashedpassword	\N	\N	t	2025-08-22 16:55:46.023042+07	2025-08-22 16:55:46.023042+07	6b3a01be-2f8c-43f3-88a6-f41a7091ebef	\N	["guest"]	pending	\N	\N
user-98-07443681@example.com	User 98	hashedpassword	\N	\N	t	2025-08-22 16:55:46.024377+07	2025-08-22 16:55:46.024377+07	07443681-7e53-4ce3-8713-a0d20c96d1cf	\N	["guest"]	pending	\N	\N
concurrent-user-2-ec627ef4@example.com	Concurrent User 2	password	\N	\N	t	2025-08-22 16:55:46.283311+07	2025-08-22 16:55:46.283312+07	ec627ef4-6502-4750-a7b7-45924770b33f	\N	["guest"]	pending	\N	\N
perf-test-0-6eb966b1@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:46.516337+07	2025-08-22 16:55:46.516337+07	6eb966b1-109b-46c7-bc87-9667fd0d7277	\N	["guest"]	pending	\N	\N
perf-test-1-6e7f36cb@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:46.517079+07	2025-08-22 16:55:46.517079+07	6e7f36cb-4661-44d2-8695-654eaa702f48	\N	["guest"]	pending	\N	\N
perf-test-2-ea703610@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:46.517834+07	2025-08-22 16:55:46.517834+07	ea703610-860f-42b9-b2a8-518d67454023	\N	["guest"]	pending	\N	\N
perf-test-3-089d2126@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:46.518336+07	2025-08-22 16:55:46.518336+07	089d2126-091a-4f0e-86dc-c9684c78933d	\N	["guest"]	pending	\N	\N
perf-test-4-da56478f@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:46.518791+07	2025-08-22 16:55:46.518791+07	da56478f-4d9a-4833-8e63-2aef0bcefcc6	\N	["guest"]	pending	\N	\N
perf-test-5-c657c2a6@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:46.519399+07	2025-08-22 16:55:46.519399+07	c657c2a6-2c5b-4a92-b22c-396462f872f7	\N	["guest"]	pending	\N	\N
perf-test-6-dad58b8c@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:46.519916+07	2025-08-22 16:55:46.519916+07	dad58b8c-2dc7-44be-8b41-f7052d2bd8d4	\N	["guest"]	pending	\N	\N
perf-test-7-d4157dc8@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:46.520392+07	2025-08-22 16:55:46.520392+07	d4157dc8-956b-42bd-80b9-ddd730eabff4	\N	["guest"]	pending	\N	\N
perf-test-8-621d0a66@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:46.520887+07	2025-08-22 16:55:46.520887+07	621d0a66-580d-4fad-afd0-8329d719d0ce	\N	["guest"]	pending	\N	\N
perf-test-9-9dde81aa@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:46.521348+07	2025-08-22 16:55:46.521348+07	9dde81aa-e5a5-47d8-9775-114afa083758	\N	["guest"]	pending	\N	\N
perf-test-10-b656f612@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:46.521841+07	2025-08-22 16:55:46.521841+07	b656f612-24b7-4b0b-8a2f-7ccb1ef58223	\N	["guest"]	pending	\N	\N
perf-test-11-edafe39c@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:46.522296+07	2025-08-22 16:55:46.522296+07	edafe39c-20fe-4a99-94db-44cbb39e9efb	\N	["guest"]	pending	\N	\N
perf-test-12-104e50ae@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:46.522765+07	2025-08-22 16:55:46.522765+07	104e50ae-5512-4eb2-b579-749c7267b5e7	\N	["guest"]	pending	\N	\N
perf-test-13-0c765af6@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:46.523174+07	2025-08-22 16:55:46.523174+07	0c765af6-a999-4385-97fd-af0fcf80c2d1	\N	["guest"]	pending	\N	\N
perf-test-14-f616030c@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:46.523567+07	2025-08-22 16:55:46.523567+07	f616030c-e2b8-42e4-8d81-3c67b4c1f572	\N	["guest"]	pending	\N	\N
perf-test-15-96fcd242@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:46.523935+07	2025-08-22 16:55:46.523935+07	96fcd242-27d2-44a8-8e37-870ff61a7585	\N	["guest"]	pending	\N	\N
perf-test-16-3278a1b9@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:46.524339+07	2025-08-22 16:55:46.524339+07	3278a1b9-02ae-42f3-b30e-eaabb6d3f5f5	\N	["guest"]	pending	\N	\N
perf-test-17-4c0e2640@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:46.52469+07	2025-08-22 16:55:46.524691+07	4c0e2640-0d4c-4513-981e-fc360b4fe67d	\N	["guest"]	pending	\N	\N
perf-test-18-33ad3ec2@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:46.525043+07	2025-08-22 16:55:46.525044+07	33ad3ec2-2b36-416d-849f-a1d06cd23fa1	\N	["guest"]	pending	\N	\N
perf-test-19-68e523b3@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:46.525392+07	2025-08-22 16:55:46.525392+07	68e523b3-7c10-42c1-be29-8bb5b83185d3	\N	["guest"]	pending	\N	\N
perf-test-20-31eae93d@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:46.525722+07	2025-08-22 16:55:46.525722+07	31eae93d-7144-4df8-afca-4e88ef0d2e5c	\N	["guest"]	pending	\N	\N
perf-test-21-d7076cb0@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:46.526088+07	2025-08-22 16:55:46.526089+07	d7076cb0-9f20-40c6-a74e-f5d5b2f4ab6d	\N	["guest"]	pending	\N	\N
perf-test-22-3ddc232d@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:46.526437+07	2025-08-22 16:55:46.526437+07	3ddc232d-09c0-4090-b7e4-2abc08561a5d	\N	["guest"]	pending	\N	\N
perf-test-23-13170730@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:46.526783+07	2025-08-22 16:55:46.526783+07	13170730-3ab2-431b-b18c-6a10ef29d948	\N	["guest"]	pending	\N	\N
perf-test-24-a2974e64@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:46.527248+07	2025-08-22 16:55:46.527248+07	a2974e64-87da-44e1-b2d5-cfffef0c93b3	\N	["guest"]	pending	\N	\N
perf-test-25-9f8526b7@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:46.52759+07	2025-08-22 16:55:46.52759+07	9f8526b7-0a8f-4947-9ac5-19ab4f8bfdba	\N	["guest"]	pending	\N	\N
perf-test-26-4912ad04@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:46.527981+07	2025-08-22 16:55:46.527981+07	4912ad04-3585-4675-ac48-bcaa36e4e43d	\N	["guest"]	pending	\N	\N
perf-test-27-161563c0@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:46.528377+07	2025-08-22 16:55:46.528377+07	161563c0-53ac-4f77-8c45-f29bb8c493bc	\N	["guest"]	pending	\N	\N
perf-test-28-86cc6650@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:46.528766+07	2025-08-22 16:55:46.528766+07	86cc6650-d46b-4d82-8571-a165bc42aea5	\N	["guest"]	pending	\N	\N
perf-test-29-14af2511@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:46.529131+07	2025-08-22 16:55:46.529131+07	14af2511-d5c1-43c9-b64e-a12970b8a68f	\N	["guest"]	pending	\N	\N
perf-test-30-20d78c84@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:46.529578+07	2025-08-22 16:55:46.529578+07	20d78c84-ff2b-4010-8537-115ae2cb4407	\N	["guest"]	pending	\N	\N
perf-test-31-28209b6a@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:46.530089+07	2025-08-22 16:55:46.530089+07	28209b6a-cd4f-4460-9a3d-f43fd09a568c	\N	["guest"]	pending	\N	\N
perf-test-32-b561de49@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:46.530647+07	2025-08-22 16:55:46.530647+07	b561de49-e565-4aca-86c1-c23a43904c8a	\N	["guest"]	pending	\N	\N
perf-test-33-b1114a06@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:46.531167+07	2025-08-22 16:55:46.531168+07	b1114a06-a205-4331-8b4c-c0fb101c60e0	\N	["guest"]	pending	\N	\N
perf-test-34-9348b2d8@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:46.531753+07	2025-08-22 16:55:46.531753+07	9348b2d8-64c5-4010-997e-05d200955e6d	\N	["guest"]	pending	\N	\N
perf-test-35-3b8eaaa0@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:46.532322+07	2025-08-22 16:55:46.532323+07	3b8eaaa0-c7fd-49a8-a408-c18407b8083f	\N	["guest"]	pending	\N	\N
perf-test-36-72a52368@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:46.532851+07	2025-08-22 16:55:46.532851+07	72a52368-5422-4118-97b3-f029b82c7172	\N	["guest"]	pending	\N	\N
perf-test-37-ab696b88@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:46.533333+07	2025-08-22 16:55:46.533333+07	ab696b88-0076-48bc-924c-f055c62441b3	\N	["guest"]	pending	\N	\N
perf-test-38-daf94052@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:46.534055+07	2025-08-22 16:55:46.534055+07	daf94052-8c68-4f56-a19b-75a574031982	\N	["guest"]	pending	\N	\N
perf-test-39-70b7ab9c@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:46.534587+07	2025-08-22 16:55:46.534588+07	70b7ab9c-c9a2-490a-b85f-a63382c18289	\N	["guest"]	pending	\N	\N
perf-test-40-181a2aff@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:46.535103+07	2025-08-22 16:55:46.535104+07	181a2aff-6765-4b78-a393-033e711735e3	\N	["guest"]	pending	\N	\N
perf-test-41-2837bce6@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:46.53555+07	2025-08-22 16:55:46.535551+07	2837bce6-96e8-46cf-bbf5-43330a2609f5	\N	["guest"]	pending	\N	\N
perf-test-42-b415a1b6@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:46.536131+07	2025-08-22 16:55:46.536131+07	b415a1b6-f52f-4d4d-ba48-40b43dab6a9d	\N	["guest"]	pending	\N	\N
perf-test-43-271af838@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:46.536652+07	2025-08-22 16:55:46.536652+07	271af838-1149-40b3-9231-67cb74f14f4e	\N	["guest"]	pending	\N	\N
perf-test-44-3d0b9547@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:46.537128+07	2025-08-22 16:55:46.537128+07	3d0b9547-b8a7-4ba7-8fc4-8aaf66981295	\N	["guest"]	pending	\N	\N
perf-test-45-4ba536f5@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:46.537612+07	2025-08-22 16:55:46.537612+07	4ba536f5-be8f-4f8a-a157-f2538b02c208	\N	["guest"]	pending	\N	\N
perf-test-46-3e018e41@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:46.538094+07	2025-08-22 16:55:46.538094+07	3e018e41-403c-4c0b-a4d7-b3cdff8780a6	\N	["guest"]	pending	\N	\N
perf-test-47-7e9ebe78@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:46.538524+07	2025-08-22 16:55:46.538524+07	7e9ebe78-646c-492c-a3c5-b574a86c8396	\N	["guest"]	pending	\N	\N
perf-test-48-1f456cd7@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:46.538921+07	2025-08-22 16:55:46.538921+07	1f456cd7-289b-4940-aa41-83cc2228803d	\N	["guest"]	pending	\N	\N
perf-test-49-65a4db3b@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:46.539358+07	2025-08-22 16:55:46.539358+07	65a4db3b-edbf-4719-814f-46bc7d08d729	\N	["guest"]	pending	\N	\N
user-2-e10ff0f1@example.com	User 2	hashedpassword	\N	\N	t	2025-08-22 16:56:17.275245+07	2025-08-22 16:56:17.275245+07	e10ff0f1-5648-488a-8632-0c2f9d37fa14	\N	["guest"]	pending	\N	\N
user-3-117240f5@example.com	User 3	hashedpassword	\N	\N	t	2025-08-22 16:56:17.278384+07	2025-08-22 16:56:17.278384+07	117240f5-8a9d-4a50-8b2a-08c76f482387	\N	["guest"]	pending	\N	\N
user-6-f76465e9@example.com	User 6	hashedpassword	\N	\N	t	2025-08-22 16:56:17.282389+07	2025-08-22 16:56:17.282389+07	f76465e9-46d1-43d8-9bd0-ce1f6cd7daba	\N	["guest"]	pending	\N	\N
user-9-7c85ea0a@example.com	User 9	hashedpassword	\N	\N	t	2025-08-22 16:56:17.285991+07	2025-08-22 16:56:17.285991+07	7c85ea0a-9979-4e02-972c-f853bccd9f5f	\N	["guest"]	pending	\N	\N
user-11-24cfade6@example.com	User 11	hashedpassword	\N	\N	t	2025-08-22 16:56:17.287348+07	2025-08-22 16:56:17.287349+07	24cfade6-b6ab-4b76-a3db-25d6dae602ab	\N	["guest"]	pending	\N	\N
user-15-7286b472@example.com	User 15	hashedpassword	\N	\N	t	2025-08-22 16:56:17.292437+07	2025-08-22 16:56:17.292437+07	7286b472-dcab-45b1-a0c2-23f17424e99a	\N	["guest"]	pending	\N	\N
user-17-0d7f5e28@example.com	User 17	hashedpassword	\N	\N	t	2025-08-22 16:56:17.293931+07	2025-08-22 16:56:17.293931+07	0d7f5e28-8e82-48ef-acd5-c05a69f5c098	\N	["guest"]	pending	\N	\N
user-18-74c5eb33@example.com	User 18	hashedpassword	\N	\N	t	2025-08-22 16:56:17.294606+07	2025-08-22 16:56:17.294606+07	74c5eb33-5bca-4fc8-9892-41a441ccb4d5	\N	["guest"]	pending	\N	\N
user-24-9b0ddce4@example.com	User 24	hashedpassword	\N	\N	t	2025-08-22 16:56:17.29892+07	2025-08-22 16:56:17.29892+07	9b0ddce4-abe5-4a3b-b22b-c2121a05ffc4	\N	["guest"]	pending	\N	\N
user-30-048302a3@example.com	User 30	hashedpassword	\N	\N	t	2025-08-22 16:56:17.301749+07	2025-08-22 16:56:17.30175+07	048302a3-dad1-4a47-b9a8-6f2e5387f0ec	\N	["guest"]	pending	\N	\N
user-47-a3f7c553@example.com	User 47	hashedpassword	\N	\N	t	2025-08-22 16:56:17.316437+07	2025-08-22 16:56:17.316437+07	a3f7c553-609c-4b5a-9673-54878b3cc70f	\N	["guest"]	pending	\N	\N
user-48-0582f3c1@example.com	User 48	hashedpassword	\N	\N	t	2025-08-22 16:56:17.316993+07	2025-08-22 16:56:17.316993+07	0582f3c1-82ff-4127-a35a-df99e0eba8d0	\N	["guest"]	pending	\N	\N
user-49-3f3c9432@example.com	User 49	hashedpassword	\N	\N	t	2025-08-22 16:56:17.317435+07	2025-08-22 16:56:17.317435+07	3f3c9432-5932-472f-9c39-0a3a7794736b	\N	["guest"]	pending	\N	\N
user-50-59880505@example.com	User 50	hashedpassword	\N	\N	t	2025-08-22 16:56:17.317877+07	2025-08-22 16:56:17.317877+07	59880505-0e6d-453e-975a-02f247aa4491	\N	["guest"]	pending	\N	\N
user-54-0b02b8c2@example.com	User 54	hashedpassword	\N	\N	t	2025-08-22 16:56:17.319686+07	2025-08-22 16:56:17.319686+07	0b02b8c2-b10f-45e8-bea1-68d3f7aee104	\N	["guest"]	pending	\N	\N
user-60-8c5c2bf9@example.com	User 60	hashedpassword	\N	\N	t	2025-08-22 16:56:17.325334+07	2025-08-22 16:56:17.325334+07	8c5c2bf9-e085-499a-b235-83c44e5a8177	\N	["guest"]	pending	\N	\N
user-61-dacc6a47@example.com	User 61	hashedpassword	\N	\N	t	2025-08-22 16:56:17.326035+07	2025-08-22 16:56:17.326035+07	dacc6a47-327c-4530-9644-127514f0f582	\N	["guest"]	pending	\N	\N
user-62-400efd11@example.com	User 62	hashedpassword	\N	\N	t	2025-08-22 16:56:17.326654+07	2025-08-22 16:56:17.326654+07	400efd11-f75b-4317-ad74-3f663efe10ae	\N	["guest"]	pending	\N	\N
user-64-9e5d22bf@example.com	User 64	hashedpassword	\N	\N	t	2025-08-22 16:56:17.327974+07	2025-08-22 16:56:17.327974+07	9e5d22bf-c6ed-4b0f-bf2d-68491f3365b1	\N	["guest"]	pending	\N	\N
user-72-1acf7cd5@example.com	User 72	hashedpassword	\N	\N	t	2025-08-22 16:56:17.331213+07	2025-08-22 16:56:17.331213+07	1acf7cd5-41f3-4068-9c7b-2cf018973323	\N	["guest"]	pending	\N	\N
user-74-2df57c95@example.com	User 74	hashedpassword	\N	\N	t	2025-08-22 16:56:17.331951+07	2025-08-22 16:56:17.331951+07	2df57c95-3ca5-4900-84f9-daa0f96b2eaa	\N	["guest"]	pending	\N	\N
user-75-e1e22b8c@example.com	User 75	hashedpassword	\N	\N	t	2025-08-22 16:56:17.332283+07	2025-08-22 16:56:17.332283+07	e1e22b8c-cb4c-41d0-aa44-ba7ffb4fc0f5	\N	["guest"]	pending	\N	\N
user-84-b2963cd0@example.com	User 84	hashedpassword	\N	\N	t	2025-08-22 16:56:17.336359+07	2025-08-22 16:56:17.336359+07	b2963cd0-ed02-4b9e-8304-228dbcd9f54e	\N	["guest"]	pending	\N	\N
user-93-f3158b9e@example.com	User 93	hashedpassword	\N	\N	t	2025-08-22 16:56:17.345529+07	2025-08-22 16:56:17.34553+07	f3158b9e-6707-4b2c-a598-3aac8c95b608	\N	["guest"]	pending	\N	\N
user-94-f460e0a2@example.com	User 94	hashedpassword	\N	\N	t	2025-08-22 16:56:17.346116+07	2025-08-22 16:56:17.346116+07	f460e0a2-e9be-4839-ab70-44775b9d4b1f	\N	["guest"]	pending	\N	\N
user-95-32b52eee@example.com	User 95	hashedpassword	\N	\N	t	2025-08-22 16:56:17.346698+07	2025-08-22 16:56:17.346699+07	32b52eee-07c2-4fd6-b083-e56a410838d6	\N	["guest"]	pending	\N	\N
user-99-bff4ec1e@example.com	User 99	hashedpassword	\N	\N	t	2025-08-22 16:56:17.348732+07	2025-08-22 16:56:17.348732+07	bff4ec1e-4f45-4a6d-a5a6-0a0f5fa37911	\N	["guest"]	pending	\N	\N
concurrent-user-2-aa29053b@example.com	Concurrent User 2	password	\N	\N	t	2025-08-22 16:56:17.628768+07	2025-08-22 16:56:17.628768+07	aa29053b-6f3c-43fb-ba57-46625bd38f6a	\N	["guest"]	pending	\N	\N
perf-test-0-97c3d79d@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:56:17.856226+07	2025-08-22 16:56:17.856227+07	97c3d79d-1936-49bd-bb4f-cf9e441d642a	\N	["guest"]	pending	\N	\N
perf-test-1-15cb5b67@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:56:17.858155+07	2025-08-22 16:56:17.858155+07	15cb5b67-7bdb-499b-9c65-a54edeb5bc53	\N	["guest"]	pending	\N	\N
perf-test-2-33dd8ef8@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:56:17.858886+07	2025-08-22 16:56:17.858886+07	33dd8ef8-c301-4cff-a6a0-a31140ad9239	\N	["guest"]	pending	\N	\N
perf-test-3-ae88266e@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:56:17.859662+07	2025-08-22 16:56:17.859663+07	ae88266e-70f8-436c-8d38-7e62b1730fbf	\N	["guest"]	pending	\N	\N
perf-test-4-010c93f8@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:56:17.860519+07	2025-08-22 16:56:17.860519+07	010c93f8-0d9c-4bb1-9af3-5158d3a8f748	\N	["guest"]	pending	\N	\N
perf-test-5-73df2f4f@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:56:17.861417+07	2025-08-22 16:56:17.861417+07	73df2f4f-51ab-41c2-9154-ac82bad8115d	\N	["guest"]	pending	\N	\N
perf-test-6-e6a794c0@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:56:17.862505+07	2025-08-22 16:56:17.862505+07	e6a794c0-62e5-4085-80a4-189ad71aa538	\N	["guest"]	pending	\N	\N
perf-test-7-6ef3a193@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:56:17.863068+07	2025-08-22 16:56:17.863068+07	6ef3a193-8416-4d4f-97ff-a73f875dbf7e	\N	["guest"]	pending	\N	\N
perf-test-8-4cfd2013@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:56:17.863631+07	2025-08-22 16:56:17.863632+07	4cfd2013-ba12-4044-bfad-ad38ba056d5a	\N	["guest"]	pending	\N	\N
perf-test-9-96b18c8c@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:56:17.864128+07	2025-08-22 16:56:17.864128+07	96b18c8c-5999-4497-86d8-98dfb2b676f2	\N	["guest"]	pending	\N	\N
perf-test-10-0e313070@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:56:17.864581+07	2025-08-22 16:56:17.864581+07	0e313070-0be4-4101-a04e-7835e0eeb59b	\N	["guest"]	pending	\N	\N
perf-test-11-63675195@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:56:17.864991+07	2025-08-22 16:56:17.864991+07	63675195-fe8e-45f1-a0df-4696169c1ff8	\N	["guest"]	pending	\N	\N
perf-test-12-4822f4d0@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:56:17.865403+07	2025-08-22 16:56:17.865403+07	4822f4d0-b525-46ad-ad7f-c241194e2919	\N	["guest"]	pending	\N	\N
perf-test-13-ec0bd94f@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:56:17.865847+07	2025-08-22 16:56:17.865847+07	ec0bd94f-3290-4ff9-a3c3-296c1a23656f	\N	["guest"]	pending	\N	\N
perf-test-14-9ea39a2d@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:56:17.866263+07	2025-08-22 16:56:17.866263+07	9ea39a2d-e73a-426f-b300-658564564f36	\N	["guest"]	pending	\N	\N
perf-test-15-7a6e1199@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:56:17.86662+07	2025-08-22 16:56:17.86662+07	7a6e1199-d8f5-407c-85b1-8d513a2101b8	\N	["guest"]	pending	\N	\N
perf-test-16-fea4dacc@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:56:17.866976+07	2025-08-22 16:56:17.866976+07	fea4dacc-12d0-4195-b8a0-b7265e90e2e8	\N	["guest"]	pending	\N	\N
perf-test-17-f9f47e91@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:56:17.867449+07	2025-08-22 16:56:17.86745+07	f9f47e91-3828-4679-8c53-8450867b7b82	\N	["guest"]	pending	\N	\N
perf-test-18-74449a66@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:56:17.867905+07	2025-08-22 16:56:17.867905+07	74449a66-0825-42e8-a720-872f57527354	\N	["guest"]	pending	\N	\N
perf-test-19-3c2322f7@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:56:17.868285+07	2025-08-22 16:56:17.868285+07	3c2322f7-1ea7-482f-bb2f-8049177a4955	\N	["guest"]	pending	\N	\N
perf-test-20-3783d9e4@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:56:17.868711+07	2025-08-22 16:56:17.868711+07	3783d9e4-25d6-46de-8127-2f04fe239da5	\N	["guest"]	pending	\N	\N
perf-test-21-ce32e384@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:56:17.869067+07	2025-08-22 16:56:17.869067+07	ce32e384-951e-4247-b30d-5dc49fb522e2	\N	["guest"]	pending	\N	\N
perf-test-22-ba8d91c6@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:56:17.869458+07	2025-08-22 16:56:17.869459+07	ba8d91c6-8a02-47e2-9c16-4fc04c4df55a	\N	["guest"]	pending	\N	\N
perf-test-23-a1e99d7b@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:56:17.869927+07	2025-08-22 16:56:17.869927+07	a1e99d7b-11ba-4ef0-9247-c826c3059816	\N	["guest"]	pending	\N	\N
perf-test-24-0ba34cf7@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:56:17.870361+07	2025-08-22 16:56:17.870361+07	0ba34cf7-bce8-431c-bafc-da113286caf4	\N	["guest"]	pending	\N	\N
perf-test-25-c05e84ec@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:56:17.871319+07	2025-08-22 16:56:17.871319+07	c05e84ec-8e52-4ae3-9de9-b633119848a4	\N	["guest"]	pending	\N	\N
perf-test-26-7a205a2c@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:56:17.872359+07	2025-08-22 16:56:17.872359+07	7a205a2c-d9ad-4a5f-b4a5-2466f45b405f	\N	["guest"]	pending	\N	\N
perf-test-27-69b2e1f6@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:56:17.873642+07	2025-08-22 16:56:17.873642+07	69b2e1f6-724d-4eed-9377-8e428e2acebb	\N	["guest"]	pending	\N	\N
perf-test-28-f4362224@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:56:17.874492+07	2025-08-22 16:56:17.874492+07	f4362224-4802-455c-88ad-3d946fbf3203	\N	["guest"]	pending	\N	\N
perf-test-29-8e96bc50@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:56:17.875055+07	2025-08-22 16:56:17.875055+07	8e96bc50-663f-421f-8cb9-8c0c26b01f7f	\N	["guest"]	pending	\N	\N
perf-test-30-b2e8dd29@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:56:17.875615+07	2025-08-22 16:56:17.875615+07	b2e8dd29-8762-43c7-85f5-48356f4d2d54	\N	["guest"]	pending	\N	\N
perf-test-31-9c760e9b@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:56:17.876116+07	2025-08-22 16:56:17.876117+07	9c760e9b-8ea1-4869-b631-900590f325ab	\N	["guest"]	pending	\N	\N
perf-test-32-bfb7d20e@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:56:17.87665+07	2025-08-22 16:56:17.87665+07	bfb7d20e-9b87-41bf-8843-1fe733414442	\N	["guest"]	pending	\N	\N
perf-test-33-17a08a77@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:56:17.877138+07	2025-08-22 16:56:17.877138+07	17a08a77-f4a2-4cc1-85d0-5a2ea419297e	\N	["guest"]	pending	\N	\N
perf-test-34-de3221f3@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:56:17.877638+07	2025-08-22 16:56:17.877638+07	de3221f3-0d5f-4aa5-b6b1-700c088d0520	\N	["guest"]	pending	\N	\N
perf-test-35-34ebff32@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:56:17.8781+07	2025-08-22 16:56:17.8781+07	34ebff32-06f0-4761-bc28-da6d13106762	\N	["guest"]	pending	\N	\N
perf-test-36-f6b27fbd@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:56:17.878525+07	2025-08-22 16:56:17.878525+07	f6b27fbd-750a-4365-8ec3-adfbd3db3c48	\N	["guest"]	pending	\N	\N
perf-test-37-8da854ae@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:56:17.878939+07	2025-08-22 16:56:17.878939+07	8da854ae-7f5f-4090-925e-0fec0cd86bfd	\N	["guest"]	pending	\N	\N
perf-test-38-abe54b81@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:56:17.879333+07	2025-08-22 16:56:17.879333+07	abe54b81-0f15-4747-a865-a295a23bb219	\N	["guest"]	pending	\N	\N
perf-test-39-0ec5d93c@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:56:17.879713+07	2025-08-22 16:56:17.879713+07	0ec5d93c-442d-4e63-85f9-15811e4d58f7	\N	["guest"]	pending	\N	\N
perf-test-40-f2ddb5a3@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:56:17.880091+07	2025-08-22 16:56:17.880091+07	f2ddb5a3-b9c5-495c-8165-d2de481d281c	\N	["guest"]	pending	\N	\N
perf-test-41-bacefb4d@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:56:17.880477+07	2025-08-22 16:56:17.880477+07	bacefb4d-21f8-445d-9386-74a3b417c1bd	\N	["guest"]	pending	\N	\N
perf-test-42-4d971b7c@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:56:17.880863+07	2025-08-22 16:56:17.880863+07	4d971b7c-7604-48ce-a20b-7bbadd0c0f77	\N	["guest"]	pending	\N	\N
perf-test-43-56511b66@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:56:17.881201+07	2025-08-22 16:56:17.881201+07	56511b66-a261-43aa-a34d-c3b1dd6d0df8	\N	["guest"]	pending	\N	\N
perf-test-44-c298e3de@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:56:17.881554+07	2025-08-22 16:56:17.881554+07	c298e3de-2ddc-4e13-8a1c-1a700460dfb2	\N	["guest"]	pending	\N	\N
perf-test-45-53780815@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:56:17.881889+07	2025-08-22 16:56:17.881889+07	53780815-dc10-4e63-b310-77f454d76723	\N	["guest"]	pending	\N	\N
perf-test-46-76d9fe67@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:56:17.882361+07	2025-08-22 16:56:17.882361+07	76d9fe67-9d06-497f-9302-1262eda7c85b	\N	["guest"]	pending	\N	\N
perf-test-47-f5ec69c3@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:56:17.882842+07	2025-08-22 16:56:17.882842+07	f5ec69c3-0e0d-4169-99cc-7a0de46771de	\N	["guest"]	pending	\N	\N
perf-test-48-726a5c4b@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:56:17.88323+07	2025-08-22 16:56:17.88323+07	726a5c4b-e8ee-4aaa-8d4b-6142075dde46	\N	["guest"]	pending	\N	\N
perf-test-49-316e2ec1@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:56:17.88361+07	2025-08-22 16:56:17.88361+07	316e2ec1-f923-42b6-96a4-0d81d508a0a8	\N	["guest"]	pending	\N	\N
user-8-af423cc8@example.com	User 8	hashedpassword	\N	\N	t	2025-08-22 17:35:45.203366+07	2025-08-22 17:35:45.203366+07	af423cc8-c67f-419b-a16e-2fa30dfc28a8	\N	["guest"]	pending	\N	\N
user-15-36439baa@example.com	User 15	hashedpassword	\N	\N	t	2025-08-22 17:35:45.208829+07	2025-08-22 17:35:45.20883+07	36439baa-a2ea-49ce-87f0-91f192446c96	\N	["guest"]	pending	\N	\N
user-16-38bef52b@example.com	User 16	hashedpassword	\N	\N	t	2025-08-22 17:35:45.209262+07	2025-08-22 17:35:45.209262+07	38bef52b-260c-45a3-9a55-8b2a499e58af	\N	["guest"]	pending	\N	\N
user-19-4ff1dc2b@example.com	User 19	hashedpassword	\N	\N	t	2025-08-22 17:35:45.210335+07	2025-08-22 17:35:45.210335+07	4ff1dc2b-ff2e-485f-91d2-2fa9df35ca40	\N	["guest"]	pending	\N	\N
user-24-d3657f83@example.com	User 24	hashedpassword	\N	\N	t	2025-08-22 17:35:45.212106+07	2025-08-22 17:35:45.212106+07	d3657f83-167a-468d-ab12-050d542c02f0	\N	["guest"]	pending	\N	\N
user-26-d7b1aa70@example.com	User 26	hashedpassword	\N	\N	t	2025-08-22 17:35:45.212777+07	2025-08-22 17:35:45.212777+07	d7b1aa70-88c2-43a2-9ccd-4199dfe99d0f	\N	["guest"]	pending	\N	\N
user-32-ac0c7232@example.com	User 32	hashedpassword	\N	\N	t	2025-08-22 17:35:45.215916+07	2025-08-22 17:35:45.215916+07	ac0c7232-f145-46c4-a8b9-0d9f461f0da5	\N	["guest"]	pending	\N	\N
user-37-98b858b0@example.com	User 37	hashedpassword	\N	\N	t	2025-08-22 17:35:45.218027+07	2025-08-22 17:35:45.218028+07	98b858b0-0f8a-4688-b061-8e1bf266e3de	\N	["guest"]	pending	\N	\N
user-39-fb7c2b59@example.com	User 39	hashedpassword	\N	\N	t	2025-08-22 17:35:45.218824+07	2025-08-22 17:35:45.218824+07	fb7c2b59-7be0-4f76-825a-8d059dda6a3c	\N	["guest"]	pending	\N	\N
user-40-235f1dbd@example.com	User 40	hashedpassword	\N	\N	t	2025-08-22 17:35:45.219188+07	2025-08-22 17:35:45.219188+07	235f1dbd-38e5-4d5a-880d-401e4dfd8fb8	\N	["guest"]	pending	\N	\N
user-46-1ba3844d@example.com	User 46	hashedpassword	\N	\N	t	2025-08-22 17:35:45.221594+07	2025-08-22 17:35:45.221594+07	1ba3844d-175c-4511-b38b-fbc1a4d640e8	\N	["guest"]	pending	\N	\N
user-51-036d1391@example.com	User 51	hashedpassword	\N	\N	t	2025-08-22 17:35:45.223898+07	2025-08-22 17:35:45.223898+07	036d1391-8b9f-41ae-abc3-818ec0218ce7	\N	["guest"]	pending	\N	\N
user-53-72275bf6@example.com	User 53	hashedpassword	\N	\N	t	2025-08-22 17:35:45.224678+07	2025-08-22 17:35:45.224678+07	72275bf6-d050-40ad-9995-8c6f28a2bb6b	\N	["guest"]	pending	\N	\N
user-55-335f057e@example.com	User 55	hashedpassword	\N	\N	t	2025-08-22 17:35:45.225431+07	2025-08-22 17:35:45.225431+07	335f057e-146e-4c04-b86d-66523cd4f5a7	\N	["guest"]	pending	\N	\N
user-58-c2ee235e@example.com	User 58	hashedpassword	\N	\N	t	2025-08-22 17:35:45.226687+07	2025-08-22 17:35:45.226687+07	c2ee235e-1ae7-46f9-812f-bbc6bdbf77cb	\N	["guest"]	pending	\N	\N
user-59-6fc8d1c5@example.com	User 59	hashedpassword	\N	\N	t	2025-08-22 17:35:45.227036+07	2025-08-22 17:35:45.227036+07	6fc8d1c5-43a1-4184-990c-669801a521e0	\N	["guest"]	pending	\N	\N
user-69-ec261877@example.com	User 69	hashedpassword	\N	\N	t	2025-08-22 17:35:45.23139+07	2025-08-22 17:35:45.23139+07	ec261877-84e7-443f-b5dd-a1d779cd4f94	\N	["guest"]	pending	\N	\N
user-73-b6e21c78@example.com	User 73	hashedpassword	\N	\N	t	2025-08-22 17:35:45.232908+07	2025-08-22 17:35:45.232908+07	b6e21c78-e00f-41b0-ac73-bc1c5edc4cdf	\N	["guest"]	pending	\N	\N
user-74-40adda8b@example.com	User 74	hashedpassword	\N	\N	t	2025-08-22 17:35:45.233269+07	2025-08-22 17:35:45.233269+07	40adda8b-7d8a-42d3-b8f4-34a3e79c04b6	\N	["guest"]	pending	\N	\N
user-82-12485ba8@example.com	User 82	hashedpassword	\N	\N	t	2025-08-22 17:35:45.236199+07	2025-08-22 17:35:45.236199+07	12485ba8-9a68-47de-9e2f-25c5c263f0ac	\N	["guest"]	pending	\N	\N
user-84-4fa6c106@example.com	User 84	hashedpassword	\N	\N	t	2025-08-22 17:35:45.236967+07	2025-08-22 17:35:45.236967+07	4fa6c106-ea23-4ace-aa49-ef9e605f8ef6	\N	["guest"]	pending	\N	\N
user-87-a64809a4@example.com	User 87	hashedpassword	\N	\N	t	2025-08-22 17:35:45.238896+07	2025-08-22 17:35:45.238896+07	a64809a4-3bd3-4967-b2e7-0a2c0cfffcb1	\N	["guest"]	pending	\N	\N
user-94-95f968a3@example.com	User 94	hashedpassword	\N	\N	t	2025-08-22 17:35:45.24158+07	2025-08-22 17:35:45.24158+07	95f968a3-5d99-4479-be61-f946d84b71d4	\N	["guest"]	pending	\N	\N
user-95-e8b83d9b@example.com	User 95	hashedpassword	\N	\N	t	2025-08-22 17:35:45.241997+07	2025-08-22 17:35:45.241997+07	e8b83d9b-340c-48cb-98c5-8ab671785aef	\N	["guest"]	pending	\N	\N
user-98-3aabf45c@example.com	User 98	hashedpassword	\N	\N	t	2025-08-22 17:35:45.243073+07	2025-08-22 17:35:45.243073+07	3aabf45c-ee26-43ee-8db7-32d8aaa56148	\N	["guest"]	pending	\N	\N
concurrent-user-2-85d2e1c7@example.com	Concurrent User 2	password	\N	\N	t	2025-08-22 17:35:45.432948+07	2025-08-22 17:35:45.432948+07	85d2e1c7-e391-4905-9535-bc2687ef99f5	\N	["guest"]	pending	\N	\N
perf-test-0-4662170d@example.com	Performance User 0	password	\N	\N	t	2025-08-22 17:35:45.597587+07	2025-08-22 17:35:45.597587+07	4662170d-5ca4-493c-8ed2-0df568550782	\N	["guest"]	pending	\N	\N
perf-test-1-bb1525c4@example.com	Performance User 1	password	\N	\N	t	2025-08-22 17:35:45.598013+07	2025-08-22 17:35:45.598013+07	bb1525c4-ede9-4bea-ae74-7a8555a2a694	\N	["guest"]	pending	\N	\N
perf-test-2-cb13a388@example.com	Performance User 2	password	\N	\N	t	2025-08-22 17:35:45.598466+07	2025-08-22 17:35:45.598466+07	cb13a388-0329-4b5f-ad78-9897786e8b78	\N	["guest"]	pending	\N	\N
perf-test-3-1e08a268@example.com	Performance User 3	password	\N	\N	t	2025-08-22 17:35:45.598817+07	2025-08-22 17:35:45.598817+07	1e08a268-c6c1-4493-ba79-74a204c94ac1	\N	["guest"]	pending	\N	\N
perf-test-4-cc280608@example.com	Performance User 4	password	\N	\N	t	2025-08-22 17:35:45.599203+07	2025-08-22 17:35:45.599203+07	cc280608-ed94-466a-8e4a-9ce75a7b41d1	\N	["guest"]	pending	\N	\N
perf-test-5-7d848ca3@example.com	Performance User 5	password	\N	\N	t	2025-08-22 17:35:45.599575+07	2025-08-22 17:35:45.599575+07	7d848ca3-b35d-4eb1-8ada-198d95933363	\N	["guest"]	pending	\N	\N
perf-test-6-3adacaad@example.com	Performance User 6	password	\N	\N	t	2025-08-22 17:35:45.600002+07	2025-08-22 17:35:45.600002+07	3adacaad-bf59-4819-bded-c99da47bcd3c	\N	["guest"]	pending	\N	\N
perf-test-7-88aed38d@example.com	Performance User 7	password	\N	\N	t	2025-08-22 17:35:45.60058+07	2025-08-22 17:35:45.60058+07	88aed38d-7ba7-4ae5-9ead-29f41f87740c	\N	["guest"]	pending	\N	\N
perf-test-8-73790622@example.com	Performance User 8	password	\N	\N	t	2025-08-22 17:35:45.601255+07	2025-08-22 17:35:45.601255+07	73790622-2402-4184-8a73-7f228552841e	\N	["guest"]	pending	\N	\N
perf-test-9-775643db@example.com	Performance User 9	password	\N	\N	t	2025-08-22 17:35:45.601737+07	2025-08-22 17:35:45.601737+07	775643db-e78f-4ba8-8a68-2138831f3e44	\N	["guest"]	pending	\N	\N
perf-test-10-35762a70@example.com	Performance User 10	password	\N	\N	t	2025-08-22 17:35:45.602146+07	2025-08-22 17:35:45.602146+07	35762a70-c0bf-490f-8ef7-690ca8dc0fd2	\N	["guest"]	pending	\N	\N
perf-test-11-c05aec7f@example.com	Performance User 11	password	\N	\N	t	2025-08-22 17:35:45.602552+07	2025-08-22 17:35:45.602552+07	c05aec7f-519d-4390-8bc7-431b34c6753c	\N	["guest"]	pending	\N	\N
perf-test-12-64fee3d5@example.com	Performance User 12	password	\N	\N	t	2025-08-22 17:35:45.602935+07	2025-08-22 17:35:45.602935+07	64fee3d5-3f19-4a08-a755-fea22fc9b17c	\N	["guest"]	pending	\N	\N
perf-test-13-5082104b@example.com	Performance User 13	password	\N	\N	t	2025-08-22 17:35:45.603316+07	2025-08-22 17:35:45.603316+07	5082104b-14ce-4e0a-a8a3-c3d070b9f2f0	\N	["guest"]	pending	\N	\N
perf-test-14-07597209@example.com	Performance User 14	password	\N	\N	t	2025-08-22 17:35:45.603748+07	2025-08-22 17:35:45.603748+07	07597209-c9bc-4d8e-9268-acb43c7c6ec2	\N	["guest"]	pending	\N	\N
perf-test-15-0ff97ff0@example.com	Performance User 15	password	\N	\N	t	2025-08-22 17:35:45.604124+07	2025-08-22 17:35:45.604124+07	0ff97ff0-19e5-4905-9d84-09e59f59a482	\N	["guest"]	pending	\N	\N
perf-test-16-aebbc864@example.com	Performance User 16	password	\N	\N	t	2025-08-22 17:35:45.604502+07	2025-08-22 17:35:45.604502+07	aebbc864-7dd0-4a33-a49d-61542728ca7e	\N	["guest"]	pending	\N	\N
perf-test-17-2398e80e@example.com	Performance User 17	password	\N	\N	t	2025-08-22 17:35:45.604856+07	2025-08-22 17:35:45.604856+07	2398e80e-6610-4c34-99ec-045c7fc614b1	\N	["guest"]	pending	\N	\N
perf-test-18-140826bf@example.com	Performance User 18	password	\N	\N	t	2025-08-22 17:35:45.605243+07	2025-08-22 17:35:45.605243+07	140826bf-87ae-46c0-9968-929d253d27c3	\N	["guest"]	pending	\N	\N
perf-test-19-4ac86874@example.com	Performance User 19	password	\N	\N	t	2025-08-22 17:35:45.605601+07	2025-08-22 17:35:45.605601+07	4ac86874-c6bf-4936-a28e-2b4151cb2183	\N	["guest"]	pending	\N	\N
perf-test-20-f7d949b3@example.com	Performance User 20	password	\N	\N	t	2025-08-22 17:35:45.605966+07	2025-08-22 17:35:45.605966+07	f7d949b3-fe59-49ea-9416-c5fa324f308c	\N	["guest"]	pending	\N	\N
perf-test-21-f0e0771b@example.com	Performance User 21	password	\N	\N	t	2025-08-22 17:35:45.606328+07	2025-08-22 17:35:45.606328+07	f0e0771b-ba7e-4c69-8eff-70f3e2acda23	\N	["guest"]	pending	\N	\N
perf-test-22-06472ccc@example.com	Performance User 22	password	\N	\N	t	2025-08-22 17:35:45.606701+07	2025-08-22 17:35:45.606701+07	06472ccc-80db-410e-96fe-f69ebc50cc18	\N	["guest"]	pending	\N	\N
perf-test-23-ed322981@example.com	Performance User 23	password	\N	\N	t	2025-08-22 17:35:45.607097+07	2025-08-22 17:35:45.607097+07	ed322981-bc33-4c2c-9cf7-20ec0ef20c88	\N	["guest"]	pending	\N	\N
perf-test-24-1f6b028b@example.com	Performance User 24	password	\N	\N	t	2025-08-22 17:35:45.607459+07	2025-08-22 17:35:45.60746+07	1f6b028b-b4be-47dd-872a-8129a655bb7f	\N	["guest"]	pending	\N	\N
perf-test-25-19525ee5@example.com	Performance User 25	password	\N	\N	t	2025-08-22 17:35:45.607835+07	2025-08-22 17:35:45.607835+07	19525ee5-0955-4288-9487-6b419b1273aa	\N	["guest"]	pending	\N	\N
perf-test-26-2dcec43e@example.com	Performance User 26	password	\N	\N	t	2025-08-22 17:35:45.608445+07	2025-08-22 17:35:45.608446+07	2dcec43e-4cda-4f8b-918a-fb90300ceaaa	\N	["guest"]	pending	\N	\N
perf-test-27-35611c39@example.com	Performance User 27	password	\N	\N	t	2025-08-22 17:35:45.609063+07	2025-08-22 17:35:45.609064+07	35611c39-fa3b-49f8-a560-4e146e30babd	\N	["guest"]	pending	\N	\N
perf-test-28-d67b34a2@example.com	Performance User 28	password	\N	\N	t	2025-08-22 17:35:45.609501+07	2025-08-22 17:35:45.609501+07	d67b34a2-2e1c-4d85-8363-d907902174d2	\N	["guest"]	pending	\N	\N
perf-test-29-04a4540e@example.com	Performance User 29	password	\N	\N	t	2025-08-22 17:35:45.610075+07	2025-08-22 17:35:45.610075+07	04a4540e-bd14-4b7d-8053-ab938f2634e2	\N	["guest"]	pending	\N	\N
perf-test-30-3b1b4c7f@example.com	Performance User 30	password	\N	\N	t	2025-08-22 17:35:45.610463+07	2025-08-22 17:35:45.610464+07	3b1b4c7f-79ae-475f-be46-580a8b9a7bdb	\N	["guest"]	pending	\N	\N
perf-test-31-c3658ba7@example.com	Performance User 31	password	\N	\N	t	2025-08-22 17:35:45.610885+07	2025-08-22 17:35:45.610886+07	c3658ba7-5ef0-4708-8ba9-3ab5ef6a962f	\N	["guest"]	pending	\N	\N
perf-test-32-f0cbb46f@example.com	Performance User 32	password	\N	\N	t	2025-08-22 17:35:45.611283+07	2025-08-22 17:35:45.611283+07	f0cbb46f-26dd-4d1b-a853-0c1ff37e3999	\N	["guest"]	pending	\N	\N
perf-test-33-c0c47a36@example.com	Performance User 33	password	\N	\N	t	2025-08-22 17:35:45.611655+07	2025-08-22 17:35:45.611655+07	c0c47a36-c2c1-48e1-a4c5-179aa2a9ae94	\N	["guest"]	pending	\N	\N
perf-test-34-69d9fa39@example.com	Performance User 34	password	\N	\N	t	2025-08-22 17:35:45.61202+07	2025-08-22 17:35:45.61202+07	69d9fa39-b83a-45c4-b328-857a1debd3cb	\N	["guest"]	pending	\N	\N
perf-test-35-b810142e@example.com	Performance User 35	password	\N	\N	t	2025-08-22 17:35:45.612423+07	2025-08-22 17:35:45.612423+07	b810142e-6030-4307-9c9d-1bddb7f5ab53	\N	["guest"]	pending	\N	\N
perf-test-36-cf14e5af@example.com	Performance User 36	password	\N	\N	t	2025-08-22 17:35:45.613037+07	2025-08-22 17:35:45.613037+07	cf14e5af-bdd1-4502-85cb-19f77c543f4f	\N	["guest"]	pending	\N	\N
perf-test-37-6715eba9@example.com	Performance User 37	password	\N	\N	t	2025-08-22 17:35:45.613458+07	2025-08-22 17:35:45.613458+07	6715eba9-6291-4c82-a8af-23e4082adabc	\N	["guest"]	pending	\N	\N
perf-test-38-9a904666@example.com	Performance User 38	password	\N	\N	t	2025-08-22 17:35:45.613835+07	2025-08-22 17:35:45.613835+07	9a904666-21ad-4c3e-9dce-5e7a2e03785b	\N	["guest"]	pending	\N	\N
perf-test-39-6351aa80@example.com	Performance User 39	password	\N	\N	t	2025-08-22 17:35:45.61432+07	2025-08-22 17:35:45.61432+07	6351aa80-96db-4ad2-910c-ad18c45f9990	\N	["guest"]	pending	\N	\N
perf-test-40-26b2af72@example.com	Performance User 40	password	\N	\N	t	2025-08-22 17:35:45.615473+07	2025-08-22 17:35:45.615473+07	26b2af72-f4a5-4167-9810-e5644e017a11	\N	["guest"]	pending	\N	\N
perf-test-41-aa5d07e0@example.com	Performance User 41	password	\N	\N	t	2025-08-22 17:35:45.616166+07	2025-08-22 17:35:45.616166+07	aa5d07e0-7ec9-4dcb-8bde-b178c49a7c34	\N	["guest"]	pending	\N	\N
perf-test-42-7f682db6@example.com	Performance User 42	password	\N	\N	t	2025-08-22 17:35:45.617188+07	2025-08-22 17:35:45.617188+07	7f682db6-49c4-430f-88fa-598cca938b23	\N	["guest"]	pending	\N	\N
perf-test-43-4dbc303f@example.com	Performance User 43	password	\N	\N	t	2025-08-22 17:35:45.618027+07	2025-08-22 17:35:45.618027+07	4dbc303f-1dbc-41b0-b409-577e73183c46	\N	["guest"]	pending	\N	\N
perf-test-44-da44689e@example.com	Performance User 44	password	\N	\N	t	2025-08-22 17:35:45.618547+07	2025-08-22 17:35:45.618548+07	da44689e-b0a0-47f7-9f08-3e7afcff16d6	\N	["guest"]	pending	\N	\N
perf-test-45-a5f67517@example.com	Performance User 45	password	\N	\N	t	2025-08-22 17:35:45.619007+07	2025-08-22 17:35:45.619007+07	a5f67517-463a-4272-a35c-422c51108994	\N	["guest"]	pending	\N	\N
perf-test-46-5bac769f@example.com	Performance User 46	password	\N	\N	t	2025-08-22 17:35:45.619465+07	2025-08-22 17:35:45.619465+07	5bac769f-ae3d-4964-b18a-fddbbbb600c4	\N	["guest"]	pending	\N	\N
perf-test-47-be8eb01e@example.com	Performance User 47	password	\N	\N	t	2025-08-22 17:35:45.619892+07	2025-08-22 17:35:45.619893+07	be8eb01e-80f9-4778-9dd4-efc07fa94dd1	\N	["guest"]	pending	\N	\N
perf-test-48-17272aa3@example.com	Performance User 48	password	\N	\N	t	2025-08-22 17:35:45.620364+07	2025-08-22 17:35:45.620364+07	17272aa3-e693-4224-b207-35ad907de297	\N	["guest"]	pending	\N	\N
perf-test-49-3dc6c379@example.com	Performance User 49	password	\N	\N	t	2025-08-22 17:35:45.62089+07	2025-08-22 17:35:45.62089+07	3dc6c379-d2cd-45b2-a024-d787e0565a4f	\N	["guest"]	pending	\N	\N
user-0-88fe7ce7@example.com	User 0	hashedpassword	\N	\N	t	2025-08-29 20:22:55.099459+07	2025-08-29 20:22:55.099459+07	88fe7ce7-d7a8-48bf-a3b2-6f98b3301db9	\N	["guest"]	pending	\N	\N
user-2-3f3c7a0c@example.com	User 2	hashedpassword	\N	\N	t	2025-08-29 20:22:55.13197+07	2025-08-29 20:22:55.131971+07	3f3c7a0c-c75e-4e94-9fbb-304c381f055c	\N	["guest"]	pending	\N	\N
user-12-9672e21e@example.com	User 12	hashedpassword	\N	\N	t	2025-08-29 20:22:55.157043+07	2025-08-29 20:22:55.157043+07	9672e21e-2946-4384-b870-7293a236fd58	\N	["guest"]	pending	\N	\N
user-15-f528f107@example.com	User 15	hashedpassword	\N	\N	t	2025-08-29 20:22:55.15869+07	2025-08-29 20:22:55.15869+07	f528f107-79b2-4016-8e42-73f9c4a853c7	\N	["guest"]	pending	\N	\N
user-25-20abc2cc@example.com	User 25	hashedpassword	\N	\N	t	2025-08-29 20:22:55.166045+07	2025-08-29 20:22:55.166045+07	20abc2cc-031d-4f26-813d-8eb81eb24278	\N	["guest"]	pending	\N	\N
user-28-7202d79c@example.com	User 28	hashedpassword	\N	\N	t	2025-08-29 20:22:55.168056+07	2025-08-29 20:22:55.168056+07	7202d79c-dacd-4fba-a2e6-05780d5d8713	\N	["guest"]	pending	\N	\N
user-31-d7a782b9@example.com	User 31	hashedpassword	\N	\N	t	2025-08-29 20:22:55.169907+07	2025-08-29 20:22:55.169907+07	d7a782b9-1e61-4434-a948-bb0348c40a6f	\N	["guest"]	pending	\N	\N
user-32-ff0f8b26@example.com	User 32	hashedpassword	\N	\N	t	2025-08-29 20:22:55.170519+07	2025-08-29 20:22:55.170519+07	ff0f8b26-733c-4136-8003-98f4afb7da08	\N	["guest"]	pending	\N	\N
user-53-98dd033d@example.com	User 53	hashedpassword	\N	\N	t	2025-08-29 20:22:55.182401+07	2025-08-29 20:22:55.182401+07	98dd033d-eafb-4513-ba0c-4725e573d395	\N	["guest"]	pending	\N	\N
user-55-68172226@example.com	User 55	hashedpassword	\N	\N	t	2025-08-29 20:22:55.183184+07	2025-08-29 20:22:55.183184+07	68172226-bf34-4456-bf60-944cbbab7edd	\N	["guest"]	pending	\N	\N
user-58-4b693186@example.com	User 58	hashedpassword	\N	\N	t	2025-08-29 20:22:55.18464+07	2025-08-29 20:22:55.184641+07	4b693186-48d8-4a1a-ac7b-b76d915a4b24	\N	["guest"]	pending	\N	\N
user-65-f226f09d@example.com	User 65	hashedpassword	\N	\N	t	2025-08-29 20:22:55.188706+07	2025-08-29 20:22:55.188706+07	f226f09d-821d-4f11-b816-9add7cd882ad	\N	["guest"]	pending	\N	\N
user-66-7fbf6463@example.com	User 66	hashedpassword	\N	\N	t	2025-08-29 20:22:55.189149+07	2025-08-29 20:22:55.189149+07	7fbf6463-f1ab-4155-81e8-0486b96b422c	\N	["guest"]	pending	\N	\N
user-70-f8d5abdd@example.com	User 70	hashedpassword	\N	\N	t	2025-08-29 20:22:55.19141+07	2025-08-29 20:22:55.19141+07	f8d5abdd-da30-4ab9-a00f-e5d8d57b4eac	\N	["guest"]	pending	\N	\N
user-72-a76105ff@example.com	User 72	hashedpassword	\N	\N	t	2025-08-29 20:22:55.192456+07	2025-08-29 20:22:55.192456+07	a76105ff-d580-4e03-99a0-eef393938cfa	\N	["guest"]	pending	\N	\N
user-75-198c718d@example.com	User 75	hashedpassword	\N	\N	t	2025-08-29 20:22:55.195921+07	2025-08-29 20:22:55.195921+07	198c718d-e578-4e48-a5c8-e86b4a5dfc69	\N	["guest"]	pending	\N	\N
user-76-d9467b8a@example.com	User 76	hashedpassword	\N	\N	t	2025-08-29 20:22:55.196611+07	2025-08-29 20:22:55.196611+07	d9467b8a-a95a-476c-aed0-4d75521a9fe1	\N	["guest"]	pending	\N	\N
user-78-47fc880d@example.com	User 78	hashedpassword	\N	\N	t	2025-08-29 20:22:55.198013+07	2025-08-29 20:22:55.198013+07	47fc880d-d737-4a32-a4bc-6a9d5e549e05	\N	["guest"]	pending	\N	\N
user-86-4ad32e2d@example.com	User 86	hashedpassword	\N	\N	t	2025-08-29 20:22:55.20132+07	2025-08-29 20:22:55.20132+07	4ad32e2d-4902-419a-9bcd-0225f2ea1fea	\N	["guest"]	pending	\N	\N
concurrent-user-2-a759ccf9@example.com	Concurrent User 2	password	\N	\N	t	2025-08-29 20:22:55.469338+07	2025-08-29 20:22:55.469339+07	a759ccf9-200c-413c-a2af-96a6db5b6b97	\N	["guest"]	pending	\N	\N
perf-test-0-af3af7a7@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:22:55.667871+07	2025-08-29 20:22:55.667871+07	af3af7a7-02fc-4d77-af8a-47fce2fea8ca	\N	["guest"]	pending	\N	\N
perf-test-1-57a89c7e@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:22:55.668385+07	2025-08-29 20:22:55.668385+07	57a89c7e-824b-49cb-89a4-ada5838496b1	\N	["guest"]	pending	\N	\N
perf-test-2-2685cc1f@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:22:55.668937+07	2025-08-29 20:22:55.668937+07	2685cc1f-9460-4490-9524-47a751d47811	\N	["guest"]	pending	\N	\N
perf-test-3-4a32c88a@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:22:55.66946+07	2025-08-29 20:22:55.66946+07	4a32c88a-5ffe-4097-a44a-05fd26caecee	\N	["guest"]	pending	\N	\N
perf-test-4-ffa4f6f6@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:22:55.669975+07	2025-08-29 20:22:55.669975+07	ffa4f6f6-aa78-4122-90e0-522a6e17c558	\N	["guest"]	pending	\N	\N
perf-test-5-15337ac1@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:22:55.670521+07	2025-08-29 20:22:55.670521+07	15337ac1-5616-4237-8c75-5517368c36d9	\N	["guest"]	pending	\N	\N
perf-test-6-5de170d0@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:22:55.671044+07	2025-08-29 20:22:55.671044+07	5de170d0-e790-4da4-bf13-0819a1bae39e	\N	["guest"]	pending	\N	\N
perf-test-7-ff5dd6a3@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:22:55.671577+07	2025-08-29 20:22:55.671577+07	ff5dd6a3-e8a8-48a5-bd1d-bf2e037c0ae4	\N	["guest"]	pending	\N	\N
perf-test-8-4f0e9974@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:22:55.672014+07	2025-08-29 20:22:55.672014+07	4f0e9974-a1ad-4fef-b790-0ac86747956a	\N	["guest"]	pending	\N	\N
perf-test-9-4727b2d6@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:22:55.672403+07	2025-08-29 20:22:55.672403+07	4727b2d6-d23a-4872-99aa-4a81c154c882	\N	["guest"]	pending	\N	\N
perf-test-10-51967bc7@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:22:55.672786+07	2025-08-29 20:22:55.672786+07	51967bc7-a142-489c-96c3-fafc46d41b9f	\N	["guest"]	pending	\N	\N
perf-test-11-a43a5c14@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:22:55.6732+07	2025-08-29 20:22:55.6732+07	a43a5c14-00fc-4062-9abe-b82c085b4616	\N	["guest"]	pending	\N	\N
perf-test-12-c125c5c1@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:22:55.673565+07	2025-08-29 20:22:55.673565+07	c125c5c1-1929-450e-87ea-91c290f1d40c	\N	["guest"]	pending	\N	\N
perf-test-13-852f2b5c@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:22:55.674006+07	2025-08-29 20:22:55.674006+07	852f2b5c-1ea6-4c40-93b4-b6391c4b6ce1	\N	["guest"]	pending	\N	\N
perf-test-14-cce11f0e@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:22:55.674393+07	2025-08-29 20:22:55.674393+07	cce11f0e-e4f8-47e5-9cac-0ebfb18e2bb6	\N	["guest"]	pending	\N	\N
perf-test-15-e740405c@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:22:55.674814+07	2025-08-29 20:22:55.674814+07	e740405c-f26b-48fc-87d4-b3b2d68adc10	\N	["guest"]	pending	\N	\N
perf-test-16-551b790a@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:22:55.675666+07	2025-08-29 20:22:55.675666+07	551b790a-a18a-470c-a0d9-fc5cdb420ca6	\N	["guest"]	pending	\N	\N
perf-test-17-f7f19879@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:22:55.676393+07	2025-08-29 20:22:55.676393+07	f7f19879-82ab-4354-a156-f83a9188ab63	\N	["guest"]	pending	\N	\N
perf-test-18-c20d924d@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:22:55.677177+07	2025-08-29 20:22:55.677177+07	c20d924d-4c48-46f0-a4c6-9420661c14e5	\N	["guest"]	pending	\N	\N
perf-test-19-a715bf39@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:22:55.67786+07	2025-08-29 20:22:55.67786+07	a715bf39-8536-44de-9966-c92596b929fd	\N	["guest"]	pending	\N	\N
perf-test-20-21761ca1@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:22:55.678687+07	2025-08-29 20:22:55.678688+07	21761ca1-73d5-428a-8eba-87e64c567e5f	\N	["guest"]	pending	\N	\N
perf-test-21-70d6c931@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:22:55.679459+07	2025-08-29 20:22:55.679459+07	70d6c931-7bbb-49b7-b8d4-b301077e39f2	\N	["guest"]	pending	\N	\N
perf-test-22-93433e23@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:22:55.680087+07	2025-08-29 20:22:55.680087+07	93433e23-5860-482b-9505-d4d93d7d7be5	\N	["guest"]	pending	\N	\N
perf-test-23-98716675@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:22:55.680537+07	2025-08-29 20:22:55.680537+07	98716675-0478-4570-a8f9-485688452960	\N	["guest"]	pending	\N	\N
perf-test-24-5633ce05@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:22:55.680923+07	2025-08-29 20:22:55.680923+07	5633ce05-82e2-4459-854b-910a409ae5ff	\N	["guest"]	pending	\N	\N
perf-test-25-9dde6c9b@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:22:55.681304+07	2025-08-29 20:22:55.681304+07	9dde6c9b-e964-4bba-94fd-9d3f9317fb25	\N	["guest"]	pending	\N	\N
perf-test-26-a716b4e0@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:22:55.68167+07	2025-08-29 20:22:55.68167+07	a716b4e0-cf43-4047-9f36-e34b740fb604	\N	["guest"]	pending	\N	\N
perf-test-27-449ef975@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:22:55.682044+07	2025-08-29 20:22:55.682044+07	449ef975-be96-43de-8000-ad687d6bdef8	\N	["guest"]	pending	\N	\N
perf-test-28-544a1ad6@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:22:55.682394+07	2025-08-29 20:22:55.682394+07	544a1ad6-557b-45b1-8bc7-cdabdb3a25e8	\N	["guest"]	pending	\N	\N
perf-test-29-4468ab41@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:22:55.682763+07	2025-08-29 20:22:55.682763+07	4468ab41-06cc-46d9-a9b9-58240b08ae4b	\N	["guest"]	pending	\N	\N
perf-test-30-bf177fc9@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:22:55.683117+07	2025-08-29 20:22:55.683117+07	bf177fc9-e81d-44db-8ffc-a6a6a08e5f75	\N	["guest"]	pending	\N	\N
perf-test-31-162edc1a@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:22:55.683729+07	2025-08-29 20:22:55.683729+07	162edc1a-eacc-43a4-bb07-e8b4e13ed241	\N	["guest"]	pending	\N	\N
perf-test-32-19ce5d65@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:22:55.684136+07	2025-08-29 20:22:55.684136+07	19ce5d65-41ee-4214-805a-0665b64303fb	\N	["guest"]	pending	\N	\N
perf-test-33-62f8d7fb@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:22:55.684588+07	2025-08-29 20:22:55.684588+07	62f8d7fb-735b-42aa-b283-10001cf08653	\N	["guest"]	pending	\N	\N
perf-test-34-ce9721c0@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:22:55.685022+07	2025-08-29 20:22:55.685022+07	ce9721c0-84b1-4139-9a1c-c92d3e0bc15a	\N	["guest"]	pending	\N	\N
perf-test-35-c0a35071@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:22:55.6856+07	2025-08-29 20:22:55.6856+07	c0a35071-77cd-41d9-b69a-afc3aba056eb	\N	["guest"]	pending	\N	\N
perf-test-36-e97bec3a@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:22:55.686203+07	2025-08-29 20:22:55.686203+07	e97bec3a-cda7-45d0-ad96-ec1c1c642c53	\N	["guest"]	pending	\N	\N
perf-test-37-2ac1143f@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:22:55.686853+07	2025-08-29 20:22:55.686853+07	2ac1143f-1fd3-44ee-8763-4bb44156bf1a	\N	["guest"]	pending	\N	\N
perf-test-38-3e12d836@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:22:55.687391+07	2025-08-29 20:22:55.687391+07	3e12d836-273e-46f6-837a-e8bb73f4b779	\N	["guest"]	pending	\N	\N
perf-test-39-0335b40c@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:22:55.687896+07	2025-08-29 20:22:55.687896+07	0335b40c-9452-45a1-ac0b-bdcdd97949fc	\N	["guest"]	pending	\N	\N
perf-test-40-2bd365af@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:22:55.688466+07	2025-08-29 20:22:55.688466+07	2bd365af-374d-4e0d-a50b-03229387b5ab	\N	["guest"]	pending	\N	\N
perf-test-41-96e02284@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:22:55.688923+07	2025-08-29 20:22:55.688923+07	96e02284-4cd7-4ee5-b85e-31746eb23301	\N	["guest"]	pending	\N	\N
perf-test-42-358a66dc@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:22:55.689386+07	2025-08-29 20:22:55.689386+07	358a66dc-15a9-4fc5-afdd-12c97fd11ffb	\N	["guest"]	pending	\N	\N
perf-test-43-0b8dc032@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:22:55.689901+07	2025-08-29 20:22:55.689901+07	0b8dc032-d9b1-433d-a18d-b04376b575c2	\N	["guest"]	pending	\N	\N
perf-test-44-c2abcf66@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:22:55.69034+07	2025-08-29 20:22:55.69034+07	c2abcf66-2355-4afa-af98-2703c32d2625	\N	["guest"]	pending	\N	\N
perf-test-45-a61fba6f@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:22:55.690803+07	2025-08-29 20:22:55.690804+07	a61fba6f-454c-47c0-a255-2e7996f37436	\N	["guest"]	pending	\N	\N
perf-test-46-668e5bcd@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:22:55.691334+07	2025-08-29 20:22:55.691334+07	668e5bcd-c3d4-4d41-8326-15c873671e78	\N	["guest"]	pending	\N	\N
perf-test-47-0f69a14d@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:22:55.691859+07	2025-08-29 20:22:55.691859+07	0f69a14d-74a9-4d48-81ae-77dd46fbfd4e	\N	["guest"]	pending	\N	\N
perf-test-48-00ab0369@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:22:55.69237+07	2025-08-29 20:22:55.69237+07	00ab0369-b554-47f3-842d-a4b20e4bb2c9	\N	["guest"]	pending	\N	\N
perf-test-49-8fe5ace4@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:22:55.693081+07	2025-08-29 20:22:55.693081+07	8fe5ace4-8fd3-4f66-bb99-609f332b0504	\N	["guest"]	pending	\N	\N
user-3-532b0f30@example.com	User 3	hashedpassword	\N	\N	t	2025-08-29 20:59:13.131035+07	2025-08-29 20:59:13.131035+07	532b0f30-8e0a-4e10-9a2b-e9c1ded2eea4	\N	["guest"]	pending	\N	\N
user-9-0f388bdd@example.com	User 9	hashedpassword	\N	\N	t	2025-08-29 20:59:13.143235+07	2025-08-29 20:59:13.143235+07	0f388bdd-24ab-4316-961b-f06f8585fe2b	\N	["guest"]	pending	\N	\N
user-17-f356ace1@example.com	User 17	hashedpassword	\N	\N	t	2025-08-29 20:59:13.148995+07	2025-08-29 20:59:13.148995+07	f356ace1-662f-4cc7-846e-07b36dd4db6c	\N	["guest"]	pending	\N	\N
user-18-d02b232a@example.com	User 18	hashedpassword	\N	\N	t	2025-08-29 20:59:13.149473+07	2025-08-29 20:59:13.149474+07	d02b232a-d85a-457c-93b4-b5d8da9f853b	\N	["guest"]	pending	\N	\N
user-25-5a1fc504@example.com	User 25	hashedpassword	\N	\N	t	2025-08-29 20:59:13.152581+07	2025-08-29 20:59:13.152581+07	5a1fc504-e4ed-48dd-82e4-b83caab63e04	\N	["guest"]	pending	\N	\N
user-31-7fc1baa2@example.com	User 31	hashedpassword	\N	\N	t	2025-08-29 20:59:13.159179+07	2025-08-29 20:59:13.159179+07	7fc1baa2-bfb0-4c7d-910c-01472cce434e	\N	["guest"]	pending	\N	\N
user-33-d98ebbe2@example.com	User 33	hashedpassword	\N	\N	t	2025-08-29 20:59:13.160438+07	2025-08-29 20:59:13.160438+07	d98ebbe2-87e0-4224-8608-b1d39a71b662	\N	["guest"]	pending	\N	\N
user-34-c0aef3c1@example.com	User 34	hashedpassword	\N	\N	t	2025-08-29 20:59:13.161052+07	2025-08-29 20:59:13.161052+07	c0aef3c1-23c2-406e-a8a6-a4de00a279c0	\N	["guest"]	pending	\N	\N
user-37-bce56bad@example.com	User 37	hashedpassword	\N	\N	t	2025-08-29 20:59:13.163912+07	2025-08-29 20:59:13.163912+07	bce56bad-c59e-471e-b093-5e84849a6f07	\N	["guest"]	pending	\N	\N
user-39-f4252bac@example.com	User 39	hashedpassword	\N	\N	t	2025-08-29 20:59:13.164837+07	2025-08-29 20:59:13.164837+07	f4252bac-b947-4195-951b-199941ef5517	\N	["guest"]	pending	\N	\N
user-47-298b63a1@example.com	User 47	hashedpassword	\N	\N	t	2025-08-29 20:59:13.168037+07	2025-08-29 20:59:13.168038+07	298b63a1-7b30-4dd8-9006-fcf36d695c49	\N	["guest"]	pending	\N	\N
user-49-892e0a65@example.com	User 49	hashedpassword	\N	\N	t	2025-08-29 20:59:13.170167+07	2025-08-29 20:59:13.170167+07	892e0a65-93f7-4650-a0ef-4d7833228fbe	\N	["guest"]	pending	\N	\N
user-60-9dd28c13@example.com	User 60	hashedpassword	\N	\N	t	2025-08-29 20:59:13.179255+07	2025-08-29 20:59:13.179255+07	9dd28c13-27f0-4e87-97cb-f1748dc6a4cc	\N	["guest"]	pending	\N	\N
user-61-ac6b96dd@example.com	User 61	hashedpassword	\N	\N	t	2025-08-29 20:59:13.179708+07	2025-08-29 20:59:13.179708+07	ac6b96dd-65b7-4026-8bd9-97cad8410791	\N	["guest"]	pending	\N	\N
user-71-d8df409a@example.com	User 71	hashedpassword	\N	\N	t	2025-08-29 20:59:13.183795+07	2025-08-29 20:59:13.183795+07	d8df409a-1e52-42f4-90de-6eaf54f60a5c	\N	["guest"]	pending	\N	\N
user-72-1fc742c7@example.com	User 72	hashedpassword	\N	\N	t	2025-08-29 20:59:13.184191+07	2025-08-29 20:59:13.184191+07	1fc742c7-44cd-41db-90f1-9646c685e70d	\N	["guest"]	pending	\N	\N
user-74-bef84bfe@example.com	User 74	hashedpassword	\N	\N	t	2025-08-29 20:59:13.185026+07	2025-08-29 20:59:13.185026+07	bef84bfe-6d66-44fc-a191-48c641eb94bc	\N	["guest"]	pending	\N	\N
user-75-c5a16357@example.com	User 75	hashedpassword	\N	\N	t	2025-08-29 20:59:13.185438+07	2025-08-29 20:59:13.185438+07	c5a16357-6ad0-4adf-93f4-3e60086de998	\N	["guest"]	pending	\N	\N
user-84-0e4e1797@example.com	User 84	hashedpassword	\N	\N	t	2025-08-29 20:59:13.193618+07	2025-08-29 20:59:13.193618+07	0e4e1797-5bec-4b7a-b872-133b0138b227	\N	["guest"]	pending	\N	\N
user-87-efce9d28@example.com	User 87	hashedpassword	\N	\N	t	2025-08-29 20:59:13.195854+07	2025-08-29 20:59:13.195854+07	efce9d28-6ca2-45a6-a132-c30163ec5374	\N	["guest"]	pending	\N	\N
user-92-8a902469@example.com	User 92	hashedpassword	\N	\N	t	2025-08-29 20:59:13.197937+07	2025-08-29 20:59:13.197938+07	8a902469-9103-4744-b9b8-8a82e38bd005	\N	["guest"]	pending	\N	\N
user-96-362a72bd@example.com	User 96	hashedpassword	\N	\N	t	2025-08-29 20:59:13.199587+07	2025-08-29 20:59:13.199587+07	362a72bd-ad62-4922-9b4a-95f91e65a7f6	\N	["guest"]	pending	\N	\N
user-99-2f04786f@example.com	User 99	hashedpassword	\N	\N	t	2025-08-29 20:59:13.200798+07	2025-08-29 20:59:13.200798+07	2f04786f-3165-4a2a-8000-f755264a1a4a	\N	["guest"]	pending	\N	\N
concurrent-user-2-b6f6014d@example.com	Concurrent User 2	password	\N	\N	t	2025-08-29 20:59:13.418695+07	2025-08-29 20:59:13.418695+07	b6f6014d-67c4-46e0-8964-10486493f1eb	\N	["guest"]	pending	\N	\N
perf-test-0-f790dde9@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:59:13.68079+07	2025-08-29 20:59:13.68079+07	f790dde9-8e7f-4c30-99b6-cb1b30fca4e2	\N	["guest"]	pending	\N	\N
perf-test-1-d5141ab8@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:59:13.681646+07	2025-08-29 20:59:13.681646+07	d5141ab8-ca84-40a4-97d6-e57b7a790a6d	\N	["guest"]	pending	\N	\N
perf-test-2-6350786a@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:59:13.682033+07	2025-08-29 20:59:13.682033+07	6350786a-263c-4385-9c41-d85cd0dd3cf1	\N	["guest"]	pending	\N	\N
perf-test-3-7fdbfe1b@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:59:13.682398+07	2025-08-29 20:59:13.682398+07	7fdbfe1b-2dd7-4313-b0b3-0d64d1e24a35	\N	["guest"]	pending	\N	\N
perf-test-4-7870e6a2@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:59:13.682767+07	2025-08-29 20:59:13.682767+07	7870e6a2-89f6-4fb2-9d7d-417af2c743c4	\N	["guest"]	pending	\N	\N
perf-test-5-70c3fadc@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:59:13.683123+07	2025-08-29 20:59:13.683123+07	70c3fadc-6c95-4704-ae74-6e5f118c5654	\N	["guest"]	pending	\N	\N
perf-test-6-0da8a655@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:59:13.6835+07	2025-08-29 20:59:13.6835+07	0da8a655-2b80-4224-8f15-d6d40ec6e345	\N	["guest"]	pending	\N	\N
perf-test-7-abab6408@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:59:13.683863+07	2025-08-29 20:59:13.683863+07	abab6408-4e82-4aee-819e-0b12a6484ccf	\N	["guest"]	pending	\N	\N
perf-test-8-96673238@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:59:13.684225+07	2025-08-29 20:59:13.684225+07	96673238-b670-46bb-839c-40b0a31dd56a	\N	["guest"]	pending	\N	\N
perf-test-9-c63420cf@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:59:13.684585+07	2025-08-29 20:59:13.684585+07	c63420cf-095a-482a-9df8-c662cc2eb428	\N	["guest"]	pending	\N	\N
perf-test-10-9dd299cf@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:59:13.684998+07	2025-08-29 20:59:13.684998+07	9dd299cf-ef2c-4b07-a074-dd93e9173dfe	\N	["guest"]	pending	\N	\N
perf-test-11-c6c98701@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:59:13.685374+07	2025-08-29 20:59:13.685375+07	c6c98701-7c89-401c-99e4-f6588b137164	\N	["guest"]	pending	\N	\N
perf-test-12-cb1250e1@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:59:13.685777+07	2025-08-29 20:59:13.685778+07	cb1250e1-bc72-41d6-9703-38a4e8c0b592	\N	["guest"]	pending	\N	\N
perf-test-13-9d6f8bf3@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:59:13.686281+07	2025-08-29 20:59:13.686281+07	9d6f8bf3-65ce-47ce-ac22-a3a11a03e968	\N	["guest"]	pending	\N	\N
perf-test-14-2ba3540d@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:59:13.686781+07	2025-08-29 20:59:13.686781+07	2ba3540d-8af4-41a1-99c0-0bf4c8b4b2f8	\N	["guest"]	pending	\N	\N
perf-test-15-4ecd4423@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:59:13.687556+07	2025-08-29 20:59:13.687556+07	4ecd4423-6d23-4f28-a4a1-f944142a7115	\N	["guest"]	pending	\N	\N
perf-test-16-3bc646f9@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:59:13.688935+07	2025-08-29 20:59:13.688935+07	3bc646f9-062e-4eeb-87c2-bcac32a0fedc	\N	["guest"]	pending	\N	\N
perf-test-17-0a91a781@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:59:13.69048+07	2025-08-29 20:59:13.69048+07	0a91a781-aa9c-4db6-a78e-952411810d02	\N	["guest"]	pending	\N	\N
perf-test-18-a6a0a0ab@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:59:13.691584+07	2025-08-29 20:59:13.691584+07	a6a0a0ab-8568-480c-99e6-6746d12fe948	\N	["guest"]	pending	\N	\N
perf-test-19-6c47af1d@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:59:13.692126+07	2025-08-29 20:59:13.692126+07	6c47af1d-6d29-427c-9e79-c1fbbb61aa4e	\N	["guest"]	pending	\N	\N
perf-test-20-4c06c9d3@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:59:13.692832+07	2025-08-29 20:59:13.692832+07	4c06c9d3-0549-4052-a772-516aa499f825	\N	["guest"]	pending	\N	\N
perf-test-21-623efa47@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:59:13.693501+07	2025-08-29 20:59:13.693502+07	623efa47-f238-4625-9581-40532fbc7f95	\N	["guest"]	pending	\N	\N
perf-test-22-70b2ca80@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:59:13.6941+07	2025-08-29 20:59:13.6941+07	70b2ca80-acb3-4bd0-aaad-d542832bd866	\N	["guest"]	pending	\N	\N
perf-test-23-caba1f7c@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:59:13.694634+07	2025-08-29 20:59:13.694634+07	caba1f7c-83db-4111-97c6-ec0371640aa2	\N	["guest"]	pending	\N	\N
perf-test-24-ed6c6cd3@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:59:13.695057+07	2025-08-29 20:59:13.695057+07	ed6c6cd3-6e1d-4a4c-a93a-f8d5fc5bcb27	\N	["guest"]	pending	\N	\N
perf-test-25-2a36d39e@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:59:13.695439+07	2025-08-29 20:59:13.695439+07	2a36d39e-8f0f-4b57-bcdc-75e263566b40	\N	["guest"]	pending	\N	\N
perf-test-26-e9c799bf@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:59:13.695817+07	2025-08-29 20:59:13.695817+07	e9c799bf-b696-4b5f-a497-3dfcca4643bb	\N	["guest"]	pending	\N	\N
perf-test-27-63f74bc9@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:59:13.69618+07	2025-08-29 20:59:13.69618+07	63f74bc9-0f73-45aa-8f83-fa22f429036f	\N	["guest"]	pending	\N	\N
perf-test-28-7641d8d0@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:59:13.696561+07	2025-08-29 20:59:13.696561+07	7641d8d0-f4dd-44e6-b2a2-c4b21edf1326	\N	["guest"]	pending	\N	\N
perf-test-29-52374c1e@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:59:13.696924+07	2025-08-29 20:59:13.696924+07	52374c1e-edf9-44a5-a39c-7c75c8046236	\N	["guest"]	pending	\N	\N
perf-test-30-d2ecac24@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:59:13.697276+07	2025-08-29 20:59:13.697276+07	d2ecac24-6b16-425f-a0e1-b30012f872b0	\N	["guest"]	pending	\N	\N
perf-test-31-a9aa663b@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:59:13.697695+07	2025-08-29 20:59:13.697695+07	a9aa663b-0c2a-4dc0-8983-bb49a23b9645	\N	["guest"]	pending	\N	\N
perf-test-32-244f31d3@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:59:13.698168+07	2025-08-29 20:59:13.698168+07	244f31d3-aab8-435c-a7f6-b8d33f08ac4e	\N	["guest"]	pending	\N	\N
perf-test-33-f51675e9@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:59:13.698553+07	2025-08-29 20:59:13.698553+07	f51675e9-3534-46ca-9dea-da9e091e4f3f	\N	["guest"]	pending	\N	\N
perf-test-34-22b70879@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:59:13.698928+07	2025-08-29 20:59:13.698928+07	22b70879-330c-4678-9325-3f4ddc18f638	\N	["guest"]	pending	\N	\N
perf-test-35-9a7f5b04@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:59:13.699297+07	2025-08-29 20:59:13.699297+07	9a7f5b04-2e88-4ea9-88a2-bf280957064d	\N	["guest"]	pending	\N	\N
perf-test-36-4ef78ce0@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:59:13.699674+07	2025-08-29 20:59:13.699674+07	4ef78ce0-8a60-463e-a401-875e4ef3b5c7	\N	["guest"]	pending	\N	\N
perf-test-37-a253bcfb@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:59:13.700124+07	2025-08-29 20:59:13.700124+07	a253bcfb-1ac7-40b9-992a-2b24a15a80b1	\N	["guest"]	pending	\N	\N
perf-test-38-da49264e@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:59:13.700499+07	2025-08-29 20:59:13.700499+07	da49264e-d6ae-4b96-a4b9-9a2fe2d3e856	\N	["guest"]	pending	\N	\N
perf-test-39-90a108fe@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:59:13.700876+07	2025-08-29 20:59:13.700876+07	90a108fe-2537-4d31-ba7a-a26d1e81a0de	\N	["guest"]	pending	\N	\N
perf-test-40-0a0cec53@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:59:13.701221+07	2025-08-29 20:59:13.701221+07	0a0cec53-8e12-40ca-89f9-9b5a5cdf4d14	\N	["guest"]	pending	\N	\N
perf-test-41-890260bc@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:59:13.701663+07	2025-08-29 20:59:13.701663+07	890260bc-90f4-409a-a629-f62341a8698f	\N	["guest"]	pending	\N	\N
perf-test-42-8163ed8a@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:59:13.702079+07	2025-08-29 20:59:13.702079+07	8163ed8a-be87-4a02-a723-18e782f5d5b5	\N	["guest"]	pending	\N	\N
perf-test-43-9bd09eda@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:59:13.702535+07	2025-08-29 20:59:13.702535+07	9bd09eda-ff8c-4618-9464-e155c03ce621	\N	["guest"]	pending	\N	\N
perf-test-44-fd43f37c@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:59:13.702996+07	2025-08-29 20:59:13.702996+07	fd43f37c-cae9-465a-8829-cfc0004468a5	\N	["guest"]	pending	\N	\N
perf-test-45-8cc403ec@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:59:13.703722+07	2025-08-29 20:59:13.703722+07	8cc403ec-ec8c-4745-ac4e-a69657cb7dc8	\N	["guest"]	pending	\N	\N
perf-test-46-6ef25b31@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:59:13.704573+07	2025-08-29 20:59:13.704573+07	6ef25b31-1118-4e08-b294-b0f451f0d5c2	\N	["guest"]	pending	\N	\N
perf-test-47-c401c6c6@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:59:13.705404+07	2025-08-29 20:59:13.705404+07	c401c6c6-f13c-4c83-98dc-6c6e6f6313c5	\N	["guest"]	pending	\N	\N
perf-test-48-31b5bec8@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:59:13.707024+07	2025-08-29 20:59:13.707024+07	31b5bec8-d395-434b-a7b0-bc460aa452d3	\N	["guest"]	pending	\N	\N
perf-test-49-f9243281@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:59:13.708196+07	2025-08-29 20:59:13.708196+07	f9243281-d40b-4edc-966d-9e2a6fd2dc5d	\N	["guest"]	pending	\N	\N
user-0-3b6a27a4@example.com	User 0	hashedpassword	\N	\N	t	2025-08-29 21:59:39.95349+07	2025-08-29 21:59:39.95349+07	3b6a27a4-1e6d-4c50-86f1-e56f3dc91cf6	\N	["guest"]	pending	\N	\N
user-2-e3054163@example.com	User 2	hashedpassword	\N	\N	t	2025-08-29 21:59:39.96426+07	2025-08-29 21:59:39.964261+07	e3054163-b333-45e2-93a7-dc3d44539734	\N	["guest"]	pending	\N	\N
user-3-be37936e@example.com	User 3	hashedpassword	\N	\N	t	2025-08-29 21:59:39.968942+07	2025-08-29 21:59:39.968942+07	be37936e-aeab-41de-a46b-6800976e0c7e	\N	["guest"]	pending	\N	\N
user-5-028001a4@example.com	User 5	hashedpassword	\N	\N	t	2025-08-29 21:59:39.973741+07	2025-08-29 21:59:39.973741+07	028001a4-e3f7-4a16-b220-8390c55a528b	\N	["guest"]	pending	\N	\N
user-6-efa00d99@example.com	User 6	hashedpassword	\N	\N	t	2025-08-29 21:59:39.974951+07	2025-08-29 21:59:39.974951+07	efa00d99-11a4-4212-b614-59b069e34477	\N	["guest"]	pending	\N	\N
user-11-a008ba8f@example.com	User 11	hashedpassword	\N	\N	t	2025-08-29 21:59:39.986568+07	2025-08-29 21:59:39.986568+07	a008ba8f-00ff-4c49-a72b-85c5eced2470	\N	["guest"]	pending	\N	\N
user-15-d7c2a515@example.com	User 15	hashedpassword	\N	\N	t	2025-08-29 21:59:39.991549+07	2025-08-29 21:59:39.99155+07	d7c2a515-699c-4278-be0c-309521b876b2	\N	["guest"]	pending	\N	\N
user-16-6c2853ef@example.com	User 16	hashedpassword	\N	\N	t	2025-08-29 21:59:39.992732+07	2025-08-29 21:59:39.992732+07	6c2853ef-7324-4110-93e4-2f09ea42474e	\N	["guest"]	pending	\N	\N
user-31-de80e8e1@example.com	User 31	hashedpassword	\N	\N	t	2025-08-29 21:59:40.010844+07	2025-08-29 21:59:40.010844+07	de80e8e1-13de-40d4-8224-c0183d81b600	\N	["guest"]	pending	\N	\N
user-33-2363c2d6@example.com	User 33	hashedpassword	\N	\N	t	2025-08-29 21:59:40.012663+07	2025-08-29 21:59:40.012663+07	2363c2d6-6a05-4061-b0a1-6aa763005a11	\N	["guest"]	pending	\N	\N
user-35-2ba15e37@example.com	User 35	hashedpassword	\N	\N	t	2025-08-29 21:59:40.014262+07	2025-08-29 21:59:40.014262+07	2ba15e37-1172-4046-966b-29941bd1a2b4	\N	["guest"]	pending	\N	\N
user-38-c56e24d2@example.com	User 38	hashedpassword	\N	\N	t	2025-08-29 21:59:40.016259+07	2025-08-29 21:59:40.01626+07	c56e24d2-85bd-4adf-9049-b2e01bbd799a	\N	["guest"]	pending	\N	\N
user-39-d9fba2c5@example.com	User 39	hashedpassword	\N	\N	t	2025-08-29 21:59:40.017669+07	2025-08-29 21:59:40.01767+07	d9fba2c5-7583-40ea-b9a3-846379c55ec6	\N	["guest"]	pending	\N	\N
user-43-b3ef12d4@example.com	User 43	hashedpassword	\N	\N	t	2025-08-29 21:59:40.02282+07	2025-08-29 21:59:40.02282+07	b3ef12d4-7b46-47e6-847f-de2051675b96	\N	["guest"]	pending	\N	\N
user-47-505891a2@example.com	User 47	hashedpassword	\N	\N	t	2025-08-29 21:59:40.026093+07	2025-08-29 21:59:40.026094+07	505891a2-be4f-4cfc-8810-5493b5c9e764	\N	["guest"]	pending	\N	\N
user-50-47302fe5@example.com	User 50	hashedpassword	\N	\N	t	2025-08-29 21:59:40.028961+07	2025-08-29 21:59:40.028961+07	47302fe5-26ae-4a42-99c9-4d9bc7398641	\N	["guest"]	pending	\N	\N
user-51-f9bf07ab@example.com	User 51	hashedpassword	\N	\N	t	2025-08-29 21:59:40.029652+07	2025-08-29 21:59:40.029652+07	f9bf07ab-b744-42f1-ab1e-616b4d2a7745	\N	["guest"]	pending	\N	\N
user-54-60aec5b8@example.com	User 54	hashedpassword	\N	\N	t	2025-08-29 21:59:40.031444+07	2025-08-29 21:59:40.031445+07	60aec5b8-a9dc-4691-a521-f1472dfcaa10	\N	["guest"]	pending	\N	\N
user-60-c6afce5f@example.com	User 60	hashedpassword	\N	\N	t	2025-08-29 21:59:40.043246+07	2025-08-29 21:59:40.043246+07	c6afce5f-b0b8-4419-b326-6aa0becbd10e	\N	["guest"]	pending	\N	\N
user-67-47b491f9@example.com	User 67	hashedpassword	\N	\N	t	2025-08-29 21:59:40.053+07	2025-08-29 21:59:40.053001+07	47b491f9-bdf3-4b36-bac2-291ebcec361d	\N	["guest"]	pending	\N	\N
user-76-dbf2aab0@example.com	User 76	hashedpassword	\N	\N	t	2025-08-29 21:59:40.144302+07	2025-08-29 21:59:40.144302+07	dbf2aab0-c441-45dc-8ee0-a5c20f397d89	\N	["guest"]	pending	\N	\N
user-90-51c3045f@example.com	User 90	hashedpassword	\N	\N	t	2025-08-29 21:59:40.15432+07	2025-08-29 21:59:40.154321+07	51c3045f-4469-4f9f-83b1-ffef835d78f8	\N	["guest"]	pending	\N	\N
user-92-16229bfb@example.com	User 92	hashedpassword	\N	\N	t	2025-08-29 21:59:40.155689+07	2025-08-29 21:59:40.155689+07	16229bfb-6279-4ae5-9af9-73c192cf6b8d	\N	["guest"]	pending	\N	\N
user-93-4d1ea395@example.com	User 93	hashedpassword	\N	\N	t	2025-08-29 21:59:40.156396+07	2025-08-29 21:59:40.156396+07	4d1ea395-3031-4168-bfa3-324551b0e730	\N	["guest"]	pending	\N	\N
concurrent-user-2-d04e0396@example.com	Concurrent User 2	password	\N	\N	t	2025-08-29 21:59:40.598837+07	2025-08-29 21:59:40.598837+07	d04e0396-2cb0-48aa-b08f-e8e6e0d46cc4	\N	["guest"]	pending	\N	\N
perf-test-0-685af2aa@example.com	Performance User 0	password	\N	\N	t	2025-08-29 21:59:41.254954+07	2025-08-29 21:59:41.254954+07	685af2aa-0059-451d-b684-1e39007cc449	\N	["guest"]	pending	\N	\N
perf-test-1-e9adebf4@example.com	Performance User 1	password	\N	\N	t	2025-08-29 21:59:41.255693+07	2025-08-29 21:59:41.255693+07	e9adebf4-5bc7-4812-be2d-4084f7f30caa	\N	["guest"]	pending	\N	\N
perf-test-2-94a221b6@example.com	Performance User 2	password	\N	\N	t	2025-08-29 21:59:41.256283+07	2025-08-29 21:59:41.256283+07	94a221b6-94ac-4a33-858d-76b9a7dee76e	\N	["guest"]	pending	\N	\N
perf-test-3-d8ea7574@example.com	Performance User 3	password	\N	\N	t	2025-08-29 21:59:41.256879+07	2025-08-29 21:59:41.25688+07	d8ea7574-0ff4-4026-8736-40670160fc10	\N	["guest"]	pending	\N	\N
perf-test-4-149f952a@example.com	Performance User 4	password	\N	\N	t	2025-08-29 21:59:41.257515+07	2025-08-29 21:59:41.257515+07	149f952a-a20f-45da-8231-ce86ad499a99	\N	["guest"]	pending	\N	\N
perf-test-5-e9dd4f83@example.com	Performance User 5	password	\N	\N	t	2025-08-29 21:59:41.257959+07	2025-08-29 21:59:41.257959+07	e9dd4f83-3984-4403-bcf0-6b51a741cc21	\N	["guest"]	pending	\N	\N
perf-test-6-4e5a933d@example.com	Performance User 6	password	\N	\N	t	2025-08-29 21:59:41.258405+07	2025-08-29 21:59:41.258405+07	4e5a933d-2a31-41c2-90e7-0946ddd5d8d7	\N	["guest"]	pending	\N	\N
perf-test-7-61f496ae@example.com	Performance User 7	password	\N	\N	t	2025-08-29 21:59:41.258805+07	2025-08-29 21:59:41.258805+07	61f496ae-558c-4fb1-82d1-46b023986e39	\N	["guest"]	pending	\N	\N
perf-test-8-43a396fd@example.com	Performance User 8	password	\N	\N	t	2025-08-29 21:59:41.259206+07	2025-08-29 21:59:41.259206+07	43a396fd-76c3-4c15-a50c-61dbad550d41	\N	["guest"]	pending	\N	\N
perf-test-9-7e1d4611@example.com	Performance User 9	password	\N	\N	t	2025-08-29 21:59:41.259568+07	2025-08-29 21:59:41.259568+07	7e1d4611-b032-4cd1-a384-5cf5439ac074	\N	["guest"]	pending	\N	\N
perf-test-10-d511c47f@example.com	Performance User 10	password	\N	\N	t	2025-08-29 21:59:41.259982+07	2025-08-29 21:59:41.259982+07	d511c47f-9209-4288-b72f-40c41dbe5eda	\N	["guest"]	pending	\N	\N
perf-test-11-24107adb@example.com	Performance User 11	password	\N	\N	t	2025-08-29 21:59:41.260345+07	2025-08-29 21:59:41.260345+07	24107adb-53fb-46bb-811e-d1f9614c4e7d	\N	["guest"]	pending	\N	\N
perf-test-12-974e780a@example.com	Performance User 12	password	\N	\N	t	2025-08-29 21:59:41.260732+07	2025-08-29 21:59:41.260732+07	974e780a-d75d-4209-bb69-3ecb210decde	\N	["guest"]	pending	\N	\N
perf-test-13-19f8c43f@example.com	Performance User 13	password	\N	\N	t	2025-08-29 21:59:41.261173+07	2025-08-29 21:59:41.261173+07	19f8c43f-7ec2-4dde-912b-96d3e51a4957	\N	["guest"]	pending	\N	\N
perf-test-14-f3df9900@example.com	Performance User 14	password	\N	\N	t	2025-08-29 21:59:41.261597+07	2025-08-29 21:59:41.261597+07	f3df9900-cb99-4d3a-82d0-b0d4ec6861a7	\N	["guest"]	pending	\N	\N
perf-test-15-5f855018@example.com	Performance User 15	password	\N	\N	t	2025-08-29 21:59:41.262024+07	2025-08-29 21:59:41.262024+07	5f855018-e8f8-4d9a-9764-13057aa09188	\N	["guest"]	pending	\N	\N
perf-test-16-8287e3a8@example.com	Performance User 16	password	\N	\N	t	2025-08-29 21:59:41.262624+07	2025-08-29 21:59:41.262624+07	8287e3a8-9f81-4ea8-aaa1-b801a8ecaa6f	\N	["guest"]	pending	\N	\N
perf-test-17-9872b465@example.com	Performance User 17	password	\N	\N	t	2025-08-29 21:59:41.2635+07	2025-08-29 21:59:41.2635+07	9872b465-af9b-49b5-8621-d54f723c7632	\N	["guest"]	pending	\N	\N
perf-test-18-0ad5eb74@example.com	Performance User 18	password	\N	\N	t	2025-08-29 21:59:41.264311+07	2025-08-29 21:59:41.264311+07	0ad5eb74-a46b-4708-9823-cd33bb009355	\N	["guest"]	pending	\N	\N
perf-test-19-6eb68423@example.com	Performance User 19	password	\N	\N	t	2025-08-29 21:59:41.264877+07	2025-08-29 21:59:41.264877+07	6eb68423-3976-421e-b72f-09dcffe3b1e9	\N	["guest"]	pending	\N	\N
perf-test-20-c017c6c9@example.com	Performance User 20	password	\N	\N	t	2025-08-29 21:59:41.265415+07	2025-08-29 21:59:41.265415+07	c017c6c9-7c6e-4486-8601-b03221eab29a	\N	["guest"]	pending	\N	\N
perf-test-21-991b6996@example.com	Performance User 21	password	\N	\N	t	2025-08-29 21:59:41.265876+07	2025-08-29 21:59:41.265876+07	991b6996-775b-47a7-9def-20389ec1e752	\N	["guest"]	pending	\N	\N
perf-test-22-6ba8dea8@example.com	Performance User 22	password	\N	\N	t	2025-08-29 21:59:41.266372+07	2025-08-29 21:59:41.266372+07	6ba8dea8-2811-4a5b-9737-fc3d5f193179	\N	["guest"]	pending	\N	\N
perf-test-23-4cc268e9@example.com	Performance User 23	password	\N	\N	t	2025-08-29 21:59:41.266705+07	2025-08-29 21:59:41.266705+07	4cc268e9-a689-4847-8def-be0e9d7c4087	\N	["guest"]	pending	\N	\N
perf-test-24-c65360fc@example.com	Performance User 24	password	\N	\N	t	2025-08-29 21:59:41.267089+07	2025-08-29 21:59:41.267089+07	c65360fc-a90a-4bcb-ad22-ae2091d1edcb	\N	["guest"]	pending	\N	\N
perf-test-25-027d3241@example.com	Performance User 25	password	\N	\N	t	2025-08-29 21:59:41.267426+07	2025-08-29 21:59:41.267426+07	027d3241-1e06-4b9b-b141-a2941db344aa	\N	["guest"]	pending	\N	\N
perf-test-26-d85ac0c7@example.com	Performance User 26	password	\N	\N	t	2025-08-29 21:59:41.267789+07	2025-08-29 21:59:41.267789+07	d85ac0c7-a199-4b68-ad54-4266e397fa8e	\N	["guest"]	pending	\N	\N
perf-test-27-76f3f29d@example.com	Performance User 27	password	\N	\N	t	2025-08-29 21:59:41.268108+07	2025-08-29 21:59:41.268108+07	76f3f29d-bbb7-43d9-92b3-05e09207bbe4	\N	["guest"]	pending	\N	\N
perf-test-28-50db9cf7@example.com	Performance User 28	password	\N	\N	t	2025-08-29 21:59:41.268459+07	2025-08-29 21:59:41.268459+07	50db9cf7-faff-4bc2-8289-ff87f8f2c3fe	\N	["guest"]	pending	\N	\N
perf-test-29-4354c441@example.com	Performance User 29	password	\N	\N	t	2025-08-29 21:59:41.268919+07	2025-08-29 21:59:41.268919+07	4354c441-b6fe-4d51-873b-69c359d177be	\N	["guest"]	pending	\N	\N
perf-test-30-9f852d66@example.com	Performance User 30	password	\N	\N	t	2025-08-29 21:59:41.26943+07	2025-08-29 21:59:41.26943+07	9f852d66-007f-4453-ac61-7bde475a4e2a	\N	["guest"]	pending	\N	\N
perf-test-31-8a50da41@example.com	Performance User 31	password	\N	\N	t	2025-08-29 21:59:41.269915+07	2025-08-29 21:59:41.269915+07	8a50da41-c8dc-449f-a8cf-53046b483645	\N	["guest"]	pending	\N	\N
perf-test-32-73a20910@example.com	Performance User 32	password	\N	\N	t	2025-08-29 21:59:41.270708+07	2025-08-29 21:59:41.270708+07	73a20910-567d-4f84-9ec2-ee870e96723e	\N	["guest"]	pending	\N	\N
perf-test-33-fce5b0bf@example.com	Performance User 33	password	\N	\N	t	2025-08-29 21:59:41.271272+07	2025-08-29 21:59:41.271272+07	fce5b0bf-648b-4306-8e4d-4b512381024b	\N	["guest"]	pending	\N	\N
perf-test-34-e2d5d377@example.com	Performance User 34	password	\N	\N	t	2025-08-29 21:59:41.271762+07	2025-08-29 21:59:41.271762+07	e2d5d377-56a3-46a6-b43a-e2e6ca5edd01	\N	["guest"]	pending	\N	\N
perf-test-35-6b0b1353@example.com	Performance User 35	password	\N	\N	t	2025-08-29 21:59:41.272236+07	2025-08-29 21:59:41.272236+07	6b0b1353-f740-488f-ba0e-f53ce3ef41ee	\N	["guest"]	pending	\N	\N
perf-test-36-11f59163@example.com	Performance User 36	password	\N	\N	t	2025-08-29 21:59:41.27278+07	2025-08-29 21:59:41.27278+07	11f59163-9da0-43aa-ab54-a4e37793253e	\N	["guest"]	pending	\N	\N
perf-test-37-9d97dd0c@example.com	Performance User 37	password	\N	\N	t	2025-08-29 21:59:41.273324+07	2025-08-29 21:59:41.273324+07	9d97dd0c-cb61-4057-ab8b-2f46b00ab4a6	\N	["guest"]	pending	\N	\N
perf-test-38-6aec0eff@example.com	Performance User 38	password	\N	\N	t	2025-08-29 21:59:41.273859+07	2025-08-29 21:59:41.273859+07	6aec0eff-a95a-4535-9480-c44d743929ff	\N	["guest"]	pending	\N	\N
perf-test-39-c63be96c@example.com	Performance User 39	password	\N	\N	t	2025-08-29 21:59:41.274392+07	2025-08-29 21:59:41.274393+07	c63be96c-ca3f-4364-8130-6c03d871e299	\N	["guest"]	pending	\N	\N
perf-test-40-be9c2465@example.com	Performance User 40	password	\N	\N	t	2025-08-29 21:59:41.274817+07	2025-08-29 21:59:41.274817+07	be9c2465-f1f3-4d0d-90a1-a42c882d789c	\N	["guest"]	pending	\N	\N
perf-test-41-ff3c5964@example.com	Performance User 41	password	\N	\N	t	2025-08-29 21:59:41.275245+07	2025-08-29 21:59:41.275245+07	ff3c5964-9d66-447c-8d2f-60e595f85efe	\N	["guest"]	pending	\N	\N
perf-test-42-6b7bca59@example.com	Performance User 42	password	\N	\N	t	2025-08-29 21:59:41.275607+07	2025-08-29 21:59:41.275607+07	6b7bca59-f96c-4f4f-97f3-958b98a0a43f	\N	["guest"]	pending	\N	\N
perf-test-43-c6b77f01@example.com	Performance User 43	password	\N	\N	t	2025-08-29 21:59:41.275995+07	2025-08-29 21:59:41.275995+07	c6b77f01-e8be-4174-989a-5b7fce7701e1	\N	["guest"]	pending	\N	\N
perf-test-44-63b2c697@example.com	Performance User 44	password	\N	\N	t	2025-08-29 21:59:41.276328+07	2025-08-29 21:59:41.276328+07	63b2c697-cda7-4c27-8e6f-32cbbada693b	\N	["guest"]	pending	\N	\N
perf-test-45-7f756878@example.com	Performance User 45	password	\N	\N	t	2025-08-29 21:59:41.276715+07	2025-08-29 21:59:41.276715+07	7f756878-292e-4177-9586-29b54e4a53ac	\N	["guest"]	pending	\N	\N
perf-test-46-3f577bce@example.com	Performance User 46	password	\N	\N	t	2025-08-29 21:59:41.27718+07	2025-08-29 21:59:41.27718+07	3f577bce-db25-41db-949a-716de344f4ec	\N	["guest"]	pending	\N	\N
perf-test-47-859760a9@example.com	Performance User 47	password	\N	\N	t	2025-08-29 21:59:41.277565+07	2025-08-29 21:59:41.277565+07	859760a9-f6ca-4b72-9bb4-ff9d4a8c67f5	\N	["guest"]	pending	\N	\N
perf-test-48-42443294@example.com	Performance User 48	password	\N	\N	t	2025-08-29 21:59:41.277966+07	2025-08-29 21:59:41.277966+07	42443294-a8f8-44ae-8766-00e6182dd8f9	\N	["guest"]	pending	\N	\N
perf-test-49-c2a13a0d@example.com	Performance User 49	password	\N	\N	t	2025-08-29 21:59:41.278581+07	2025-08-29 21:59:41.278581+07	c2a13a0d-1dde-48e6-b561-118f17f7abcf	\N	["guest"]	pending	\N	\N
user-0-23ecef83@example.com	User 0	hashedpassword	\N	\N	t	2025-08-29 22:02:00.796674+07	2025-08-29 22:02:00.796674+07	23ecef83-887c-4c19-8af8-2d8bf5203a8f	\N	["guest"]	pending	\N	\N
user-6-f8c86636@example.com	User 6	hashedpassword	\N	\N	t	2025-08-29 22:02:00.854322+07	2025-08-29 22:02:00.854322+07	f8c86636-a772-4085-ae86-c728b2573098	\N	["guest"]	pending	\N	\N
user-10-7a34174e@example.com	User 10	hashedpassword	\N	\N	t	2025-08-29 22:02:00.857588+07	2025-08-29 22:02:00.857588+07	7a34174e-f0f9-4a32-b5d0-cb9aaced2af3	\N	["guest"]	pending	\N	\N
user-34-454c01f7@example.com	User 34	hashedpassword	\N	\N	t	2025-08-29 22:02:00.870305+07	2025-08-29 22:02:00.870305+07	454c01f7-3af6-4f1b-88b0-1bfb15cb7504	\N	["guest"]	pending	\N	\N
user-36-e64aac2b@example.com	User 36	hashedpassword	\N	\N	t	2025-08-29 22:02:00.871529+07	2025-08-29 22:02:00.871529+07	e64aac2b-461c-4198-806a-ffacf341e425	\N	["guest"]	pending	\N	\N
user-39-a6f66129@example.com	User 39	hashedpassword	\N	\N	t	2025-08-29 22:02:00.873407+07	2025-08-29 22:02:00.873408+07	a6f66129-3063-403d-8b47-d5bed60a6196	\N	["guest"]	pending	\N	\N
user-40-bc5b9b8c@example.com	User 40	hashedpassword	\N	\N	t	2025-08-29 22:02:00.873942+07	2025-08-29 22:02:00.873943+07	bc5b9b8c-b5ca-4c97-865a-9d6a7fd7469b	\N	["guest"]	pending	\N	\N
user-42-2572ec94@example.com	User 42	hashedpassword	\N	\N	t	2025-08-29 22:02:00.874923+07	2025-08-29 22:02:00.874923+07	2572ec94-db4a-4842-840d-5a8aa9d1a9e4	\N	["guest"]	pending	\N	\N
user-44-4ae7bf60@example.com	User 44	hashedpassword	\N	\N	t	2025-08-29 22:02:00.875781+07	2025-08-29 22:02:00.875782+07	4ae7bf60-4817-41e7-bab7-82a29559ff19	\N	["guest"]	pending	\N	\N
user-47-af35ae9d@example.com	User 47	hashedpassword	\N	\N	t	2025-08-29 22:02:00.876951+07	2025-08-29 22:02:00.876951+07	af35ae9d-615e-4496-bf28-0e62c6162fa8	\N	["guest"]	pending	\N	\N
user-52-61d5f2f0@example.com	User 52	hashedpassword	\N	\N	t	2025-08-29 22:02:00.879017+07	2025-08-29 22:02:00.879017+07	61d5f2f0-68c5-41fe-858b-5939188942fd	\N	["guest"]	pending	\N	\N
user-54-756798af@example.com	User 54	hashedpassword	\N	\N	t	2025-08-29 22:02:00.879925+07	2025-08-29 22:02:00.879925+07	756798af-c103-42a3-abe2-8dd88842c903	\N	["guest"]	pending	\N	\N
user-56-e76c9c1e@example.com	User 56	hashedpassword	\N	\N	t	2025-08-29 22:02:00.881124+07	2025-08-29 22:02:00.881124+07	e76c9c1e-475d-4e93-bce3-d3888d3b2e08	\N	["guest"]	pending	\N	\N
user-59-2026bb6b@example.com	User 59	hashedpassword	\N	\N	t	2025-08-29 22:02:00.883084+07	2025-08-29 22:02:00.883084+07	2026bb6b-2446-4a3d-a6c9-5cb010563f11	\N	["guest"]	pending	\N	\N
user-61-d6d84a5a@example.com	User 61	hashedpassword	\N	\N	t	2025-08-29 22:02:00.884072+07	2025-08-29 22:02:00.884072+07	d6d84a5a-6ce3-4d8f-b423-badb25f17bc6	\N	["guest"]	pending	\N	\N
user-67-00f238bf@example.com	User 67	hashedpassword	\N	\N	t	2025-08-29 22:02:00.886279+07	2025-08-29 22:02:00.886279+07	00f238bf-bf4e-4f40-b38d-d4f6b262e3c0	\N	["guest"]	pending	\N	\N
user-74-ec74b677@example.com	User 74	hashedpassword	\N	\N	t	2025-08-29 22:02:00.889508+07	2025-08-29 22:02:00.889508+07	ec74b677-63ed-44ea-b98e-c54000b1464e	\N	["guest"]	pending	\N	\N
user-83-2b5bb578@example.com	User 83	hashedpassword	\N	\N	t	2025-08-29 22:02:00.893608+07	2025-08-29 22:02:00.893608+07	2b5bb578-3119-483d-9080-bb7537e09ea9	\N	["guest"]	pending	\N	\N
user-90-e64d96e7@example.com	User 90	hashedpassword	\N	\N	t	2025-08-29 22:02:00.896533+07	2025-08-29 22:02:00.896533+07	e64d96e7-2a93-48cf-a081-7a0f7fdeb398	\N	["guest"]	pending	\N	\N
user-91-ea9b3d93@example.com	User 91	hashedpassword	\N	\N	t	2025-08-29 22:02:00.896962+07	2025-08-29 22:02:00.896962+07	ea9b3d93-69e0-4f1b-9771-ebb6eec04633	\N	["guest"]	pending	\N	\N
user-94-b4fd186d@example.com	User 94	hashedpassword	\N	\N	t	2025-08-29 22:02:00.898901+07	2025-08-29 22:02:00.898901+07	b4fd186d-8ea6-4c97-b604-e4ba91994374	\N	["guest"]	pending	\N	\N
user-96-8ec6ffd3@example.com	User 96	hashedpassword	\N	\N	t	2025-08-29 22:02:00.899998+07	2025-08-29 22:02:00.899998+07	8ec6ffd3-5f29-4ce3-a847-c34db4adb0df	\N	["guest"]	pending	\N	\N
concurrent-user-2-3021512a@example.com	Concurrent User 2	password	\N	\N	t	2025-08-29 22:02:01.174281+07	2025-08-29 22:02:01.174281+07	3021512a-31ef-4807-8fd5-9e747e757e6c	\N	["guest"]	pending	\N	\N
perf-test-0-443e93cc@example.com	Performance User 0	password	\N	\N	t	2025-08-29 22:02:01.366806+07	2025-08-29 22:02:01.366806+07	443e93cc-1b72-475a-a695-fd935e302419	\N	["guest"]	pending	\N	\N
perf-test-1-a97cede2@example.com	Performance User 1	password	\N	\N	t	2025-08-29 22:02:01.367467+07	2025-08-29 22:02:01.367467+07	a97cede2-561b-47dd-bcea-4ab470135852	\N	["guest"]	pending	\N	\N
perf-test-2-bdb924a3@example.com	Performance User 2	password	\N	\N	t	2025-08-29 22:02:01.367909+07	2025-08-29 22:02:01.367909+07	bdb924a3-b365-4ba4-9198-3cffae65708a	\N	["guest"]	pending	\N	\N
perf-test-3-c6e96625@example.com	Performance User 3	password	\N	\N	t	2025-08-29 22:02:01.368283+07	2025-08-29 22:02:01.368283+07	c6e96625-3d68-4d41-8cd3-7bd46099a40a	\N	["guest"]	pending	\N	\N
perf-test-4-f9857199@example.com	Performance User 4	password	\N	\N	t	2025-08-29 22:02:01.368636+07	2025-08-29 22:02:01.368636+07	f9857199-7c88-4928-b65b-ab6248745b1c	\N	["guest"]	pending	\N	\N
perf-test-5-32469d17@example.com	Performance User 5	password	\N	\N	t	2025-08-29 22:02:01.369009+07	2025-08-29 22:02:01.369009+07	32469d17-dcd9-4837-b564-ef99e5f0996b	\N	["guest"]	pending	\N	\N
perf-test-6-230ff519@example.com	Performance User 6	password	\N	\N	t	2025-08-29 22:02:01.369361+07	2025-08-29 22:02:01.369361+07	230ff519-f229-413b-b778-a985aa1b1156	\N	["guest"]	pending	\N	\N
perf-test-7-74474c4a@example.com	Performance User 7	password	\N	\N	t	2025-08-29 22:02:01.369745+07	2025-08-29 22:02:01.369746+07	74474c4a-ba4b-4faa-b9e7-e5a05e5db50f	\N	["guest"]	pending	\N	\N
perf-test-8-56c0922b@example.com	Performance User 8	password	\N	\N	t	2025-08-29 22:02:01.370088+07	2025-08-29 22:02:01.370088+07	56c0922b-6d4f-44d5-a72a-4208ae5df84a	\N	["guest"]	pending	\N	\N
perf-test-9-5d6c602c@example.com	Performance User 9	password	\N	\N	t	2025-08-29 22:02:01.370546+07	2025-08-29 22:02:01.370546+07	5d6c602c-d173-4964-87d7-9a9eb4e38aec	\N	["guest"]	pending	\N	\N
perf-test-10-6e0a92dd@example.com	Performance User 10	password	\N	\N	t	2025-08-29 22:02:01.371038+07	2025-08-29 22:02:01.371038+07	6e0a92dd-b8fe-424f-9f11-777a0ecfdb69	\N	["guest"]	pending	\N	\N
perf-test-11-94cb82b2@example.com	Performance User 11	password	\N	\N	t	2025-08-29 22:02:01.371544+07	2025-08-29 22:02:01.371544+07	94cb82b2-0127-4880-b2ed-8b7fa5b5b7df	\N	["guest"]	pending	\N	\N
perf-test-12-95a32d78@example.com	Performance User 12	password	\N	\N	t	2025-08-29 22:02:01.372084+07	2025-08-29 22:02:01.372084+07	95a32d78-c511-44ac-ae34-e02a1ce7fc5e	\N	["guest"]	pending	\N	\N
perf-test-13-6a7a0735@example.com	Performance User 13	password	\N	\N	t	2025-08-29 22:02:01.372612+07	2025-08-29 22:02:01.372612+07	6a7a0735-ef82-4031-bbd3-9d5911a2b47b	\N	["guest"]	pending	\N	\N
perf-test-14-4f732c55@example.com	Performance User 14	password	\N	\N	t	2025-08-29 22:02:01.37309+07	2025-08-29 22:02:01.37309+07	4f732c55-c677-4ae3-bade-ca6966d9aa83	\N	["guest"]	pending	\N	\N
perf-test-15-11ff3199@example.com	Performance User 15	password	\N	\N	t	2025-08-29 22:02:01.373582+07	2025-08-29 22:02:01.373582+07	11ff3199-d7c1-4bcb-98f0-f544b90582a4	\N	["guest"]	pending	\N	\N
perf-test-16-0730d57d@example.com	Performance User 16	password	\N	\N	t	2025-08-29 22:02:01.374112+07	2025-08-29 22:02:01.374112+07	0730d57d-7493-49e9-b629-ba8676c84bc5	\N	["guest"]	pending	\N	\N
perf-test-17-59542694@example.com	Performance User 17	password	\N	\N	t	2025-08-29 22:02:01.374581+07	2025-08-29 22:02:01.374581+07	59542694-dc3c-4534-aac1-2e85836ec69e	\N	["guest"]	pending	\N	\N
perf-test-18-b62217fd@example.com	Performance User 18	password	\N	\N	t	2025-08-29 22:02:01.374996+07	2025-08-29 22:02:01.374996+07	b62217fd-9a8e-4fb3-8721-23ab0b9a92b4	\N	["guest"]	pending	\N	\N
perf-test-19-faca53cb@example.com	Performance User 19	password	\N	\N	t	2025-08-29 22:02:01.375384+07	2025-08-29 22:02:01.375384+07	faca53cb-cfb2-4db5-9ea9-7fabd6df989e	\N	["guest"]	pending	\N	\N
perf-test-20-55c48faf@example.com	Performance User 20	password	\N	\N	t	2025-08-29 22:02:01.375801+07	2025-08-29 22:02:01.375801+07	55c48faf-461c-40be-b56b-aff372ee5028	\N	["guest"]	pending	\N	\N
perf-test-21-b681b45d@example.com	Performance User 21	password	\N	\N	t	2025-08-29 22:02:01.376168+07	2025-08-29 22:02:01.376168+07	b681b45d-36a3-4331-bed3-20c8171b8acf	\N	["guest"]	pending	\N	\N
perf-test-22-034a3590@example.com	Performance User 22	password	\N	\N	t	2025-08-29 22:02:01.376527+07	2025-08-29 22:02:01.376527+07	034a3590-50a5-45b9-8a05-9c4b8de5ab60	\N	["guest"]	pending	\N	\N
perf-test-23-06207afc@example.com	Performance User 23	password	\N	\N	t	2025-08-29 22:02:01.376963+07	2025-08-29 22:02:01.376963+07	06207afc-5d57-434d-8dd1-db57943bcdc9	\N	["guest"]	pending	\N	\N
perf-test-24-c1f0b9c9@example.com	Performance User 24	password	\N	\N	t	2025-08-29 22:02:01.377393+07	2025-08-29 22:02:01.377393+07	c1f0b9c9-a0c9-401b-a8ce-2b2745eadcb0	\N	["guest"]	pending	\N	\N
perf-test-25-6af8ce81@example.com	Performance User 25	password	\N	\N	t	2025-08-29 22:02:01.377829+07	2025-08-29 22:02:01.377829+07	6af8ce81-94aa-4cf3-9c64-cb770aaa605d	\N	["guest"]	pending	\N	\N
perf-test-26-d13b15a0@example.com	Performance User 26	password	\N	\N	t	2025-08-29 22:02:01.378259+07	2025-08-29 22:02:01.378259+07	d13b15a0-b63a-4c88-b3a3-dac0785b76a0	\N	["guest"]	pending	\N	\N
perf-test-27-7bc195e1@example.com	Performance User 27	password	\N	\N	t	2025-08-29 22:02:01.378679+07	2025-08-29 22:02:01.378679+07	7bc195e1-a856-45ae-806f-fb83012ec712	\N	["guest"]	pending	\N	\N
perf-test-28-1fba5e1b@example.com	Performance User 28	password	\N	\N	t	2025-08-29 22:02:01.379044+07	2025-08-29 22:02:01.379045+07	1fba5e1b-2113-4f21-b81c-b5390bc3b4fd	\N	["guest"]	pending	\N	\N
perf-test-29-d949707f@example.com	Performance User 29	password	\N	\N	t	2025-08-29 22:02:01.379427+07	2025-08-29 22:02:01.379427+07	d949707f-8c65-498b-a7f1-f9a070f2fb33	\N	["guest"]	pending	\N	\N
perf-test-30-40a517dd@example.com	Performance User 30	password	\N	\N	t	2025-08-29 22:02:01.379809+07	2025-08-29 22:02:01.379809+07	40a517dd-0b65-4731-9a1c-36298fc6827b	\N	["guest"]	pending	\N	\N
perf-test-31-7844a192@example.com	Performance User 31	password	\N	\N	t	2025-08-29 22:02:01.38026+07	2025-08-29 22:02:01.38026+07	7844a192-641e-42fd-9be1-cc0784873656	\N	["guest"]	pending	\N	\N
perf-test-32-25bfa26d@example.com	Performance User 32	password	\N	\N	t	2025-08-29 22:02:01.380765+07	2025-08-29 22:02:01.380765+07	25bfa26d-f490-4f5a-9dd7-1b59ff56bdae	\N	["guest"]	pending	\N	\N
perf-test-33-c99236b1@example.com	Performance User 33	password	\N	\N	t	2025-08-29 22:02:01.381313+07	2025-08-29 22:02:01.381313+07	c99236b1-51e5-4886-aa54-6460d4fd0885	\N	["guest"]	pending	\N	\N
perf-test-34-38cd001b@example.com	Performance User 34	password	\N	\N	t	2025-08-29 22:02:01.381881+07	2025-08-29 22:02:01.381881+07	38cd001b-eb1b-42f5-8a8e-c936ab813e2c	\N	["guest"]	pending	\N	\N
perf-test-35-ba32753f@example.com	Performance User 35	password	\N	\N	t	2025-08-29 22:02:01.382433+07	2025-08-29 22:02:01.382433+07	ba32753f-5d39-45fa-b671-f902edd19942	\N	["guest"]	pending	\N	\N
perf-test-36-85984fba@example.com	Performance User 36	password	\N	\N	t	2025-08-29 22:02:01.382966+07	2025-08-29 22:02:01.382966+07	85984fba-1bbb-474f-a84a-6be0cf0ece46	\N	["guest"]	pending	\N	\N
perf-test-37-4bf9212e@example.com	Performance User 37	password	\N	\N	t	2025-08-29 22:02:01.38341+07	2025-08-29 22:02:01.38341+07	4bf9212e-32e1-4da4-9ce5-5a171914e08c	\N	["guest"]	pending	\N	\N
perf-test-38-0a3bbf77@example.com	Performance User 38	password	\N	\N	t	2025-08-29 22:02:01.383907+07	2025-08-29 22:02:01.383907+07	0a3bbf77-18be-4efa-b408-73f551786ffd	\N	["guest"]	pending	\N	\N
perf-test-39-6949c688@example.com	Performance User 39	password	\N	\N	t	2025-08-29 22:02:01.384348+07	2025-08-29 22:02:01.384348+07	6949c688-e9a9-4811-936e-5fbeb54caecc	\N	["guest"]	pending	\N	\N
perf-test-40-7a91d4d0@example.com	Performance User 40	password	\N	\N	t	2025-08-29 22:02:01.384728+07	2025-08-29 22:02:01.384728+07	7a91d4d0-c5a2-453b-88a0-96308d0c66fe	\N	["guest"]	pending	\N	\N
perf-test-41-95a77682@example.com	Performance User 41	password	\N	\N	t	2025-08-29 22:02:01.385065+07	2025-08-29 22:02:01.385066+07	95a77682-aba1-4788-ba02-1d9e16d5b7e5	\N	["guest"]	pending	\N	\N
perf-test-42-16f2ecef@example.com	Performance User 42	password	\N	\N	t	2025-08-29 22:02:01.385447+07	2025-08-29 22:02:01.385447+07	16f2ecef-50d1-4e32-bb82-cf578bf4d576	\N	["guest"]	pending	\N	\N
perf-test-43-3071f93b@example.com	Performance User 43	password	\N	\N	t	2025-08-29 22:02:01.385823+07	2025-08-29 22:02:01.385823+07	3071f93b-0902-4cfe-8491-0b98122be2ad	\N	["guest"]	pending	\N	\N
perf-test-44-4e4d6479@example.com	Performance User 44	password	\N	\N	t	2025-08-29 22:02:01.386193+07	2025-08-29 22:02:01.386193+07	4e4d6479-db99-4c1e-8a80-549ad84a8cdb	\N	["guest"]	pending	\N	\N
perf-test-45-c52482fb@example.com	Performance User 45	password	\N	\N	t	2025-08-29 22:02:01.386506+07	2025-08-29 22:02:01.386506+07	c52482fb-f961-4491-8dd9-7b4d6e538941	\N	["guest"]	pending	\N	\N
perf-test-46-564943cf@example.com	Performance User 46	password	\N	\N	t	2025-08-29 22:02:01.38687+07	2025-08-29 22:02:01.38687+07	564943cf-faec-456d-956f-b000a6885396	\N	["guest"]	pending	\N	\N
perf-test-47-c0f6b5d0@example.com	Performance User 47	password	\N	\N	t	2025-08-29 22:02:01.387347+07	2025-08-29 22:02:01.387348+07	c0f6b5d0-71b5-4778-9ab2-ec9ac107ac33	\N	["guest"]	pending	\N	\N
perf-test-48-03d5fba3@example.com	Performance User 48	password	\N	\N	t	2025-08-29 22:02:01.387779+07	2025-08-29 22:02:01.387779+07	03d5fba3-3644-43ab-bfaf-c6992bbf6fdd	\N	["guest"]	pending	\N	\N
perf-test-49-5705d162@example.com	Performance User 49	password	\N	\N	t	2025-08-29 22:02:01.388282+07	2025-08-29 22:02:01.388282+07	5705d162-c41b-4524-8fc5-555ad39997ef	\N	["guest"]	pending	\N	\N
testuser1756491698791@example.com	Test User	$2a$10$tTY1vOptqNCz3veWiHCkS.7gjEd22YOmY9q2/XJlRjRcO8cYjZIVO	+1234567890	Test Address	t	2025-08-30 01:21:39.267125+07	2025-08-30 01:21:39.267125+07	16438dd7-4e97-4044-b327-dcc5131e85b0	\N	["member"]	pending	\N	\N
testuser1756491760483@example.com	Test User	$2a$10$xfgh8JfHnirGIAxGSxDF0.KSw0Y05fR.YVwqr0Po2pP7MUNWriwja	+1234567890	Test Address	t	2025-08-30 01:22:40.647514+07	2025-08-30 01:22:40.647514+07	fb538907-f237-4a74-977e-b636df6e1fb6	\N	["member"]	pending	\N	\N
admin-ryan@comfunds.com	Ryan Admin	$2a$10$ORL0PY0fwFhbrlP97Z0ERu3q88fbSi7FFkLWk.PL3k5l7d8cbhNqi	+1234567890	123 Admin Street, Admin City, AC 12345	t	2025-08-31 11:43:03.421366+07	2025-08-31 11:43:03.421366+07	ccf6b3d6-0130-466a-a5f5-32eac63b7a0d	\N	["admin"]	pending	\N	\N
reg-fix-final@example.com	Registration Fix Test	$2a$10$CGUoxv1pACFOML01dz6VDOP6cKz/ivj.1WIDy2l0TvujMvpqLnKWm	+62-822-1111-2222	Jl. Registration Fix Final No. 444, Jakarta	t	2025-09-19 22:05:51.417484+07	2025-09-19 22:05:51.417484+07	81879929-b2e1-4a8d-ba81-364acded4b28	550e8400-e29b-41d4-a716-446655440001	["investor"]	pending	\N	\N
final-test-user@example.com	Final Test User	$2a$10$oD49QqJ4HQxB33E8lcqHoec3vC.BfttNBbCbYIYetlp4yndMjuXl.	+62-823-2222-3333	Jl. Final Test No. 555, Jakarta	t	2025-09-19 22:06:09.607941+07	2025-09-19 22:06:09.607941+07	0f603a28-ebb4-481a-98d4-b9d2028a0a4b	550e8400-e29b-41d4-a716-446655440002	["business_owner", "investor"]	pending	\N	\N
tesHaji01@hajifund.com	tesHaji 001	$2a$10$4PsbVMgSOiRJjjVReqmTHeCqmO5D.U3L7WbpFVy7ROWYdESh60VLC	08113333333	jalan 1234	t	2025-09-19 22:09:25.885868+07	2025-09-19 22:09:25.885868+07	543204f7-87c4-4d9c-a4b6-f6826b8c9d32	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
businessowner@test.com	Business Owner Test	$2a$10$UJh5ox85njlmRkgRxCWbReVwGQCxDTuhSxL.qkq/5g5q1UuUbGrvu	+62-800-TEST-01	Jl. Test Business Owner	t	2025-09-20 10:21:45.559272+07	2025-09-20 10:21:45.559272+07	93a66d6a-6c6e-47e6-94bf-0b799336a0be	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
debugowner5@hajifund.com	Debug Owner 5	$2a$10$U7tK7tT5q7EG59FU.KoTa./qMdsAY4OeJYZgpxQCFt.xbT4vQc82i	+62-800-DEBUG5	Jl. Debug Owner 5 No. 1	t	2025-09-20 10:45:08.997553+07	2025-09-20 10:45:08.997553+07	102a595c-b11b-44d0-ac07-212cf453608b	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
demo-business@example.com	Demo Business Owner	$2a$10$WnP7quvVdTclQWixyVIwGukQ4L/sicoRaz29TiiqOHeE1dNsfPEGy	+6281234567890	Jl. Demo Business No. 123, Jakarta	t	2025-10-05 09:59:42.449461+07	2025-10-05 09:59:42.449461+07	123e4567-e89b-12d3-a456-426614174001	550e8400-e29b-41d4-a716-446655440001	["member", "business_owner", "investor"]	pending	\N	\N
member@hajifund.com	Demo Member	$2a$10$rur09sqb716ha12JaMpI6eN974Y80rE9lu6CA/LOE3qhdhYFgf6/a	+6281234567892	Jl. Demo Member No. 789, Jakarta	t	2025-10-05 09:59:42.473241+07	2025-10-05 09:59:42.473241+07	123e4567-e89b-12d3-a456-426614174003	550e8400-e29b-41d4-a716-446655440001	["member", "investor"]	pending	\N	\N
aliep@gmail.com	alief	$2a$10$R683W9GTIE5OLjgy6SXNB.lRLUaHF/XfLGupsxlWRiqilPW3nccuu	081134475	67 Glendive Ave	t	2025-10-11 22:40:28.886979+07	2025-10-11 22:40:28.886979+07	672529e8-f0e5-4679-b3a7-9e2ab9fc9cfb	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
user2@hajifund.id	User2	$2a$10$RZMBAJez4eV0/1UOcsmBG.0nag7bczx7pEdlSbjCwCx.QBCjGtAGu	+6212323424536	Jl. Satu Arah	t	2025-10-18 13:26:25.702167+07	2025-10-18 13:26:25.702167+07	a959b178-3cf7-4b42-a22e-986baae8a784	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
tesCoba@hajifund.com	testCoba A1234	$2a$10$QSfKBGs6CP4GLSl5ndoCCOPS8e1oVXCxEHoQGjwYcozz9Rf/R/Moi	+6281933999574	Jl. Coba	t	2025-10-19 20:39:47.140058+07	2025-10-19 20:39:47.140058+07	969906a6-120d-4dda-8051-caddc0e09bd2	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner"]	pending	\N	\N
\.


--
-- TOC entry 3903 (class 0 OID 0)
-- Dependencies: 220
-- Name: global_transaction_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.global_transaction_seq', 1000000, false);


--
-- TOC entry 3904 (class 0 OID 0)
-- Dependencies: 227
-- Name: idempotency_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.idempotency_sequence', 1, false);


--
-- TOC entry 3687 (class 2606 OID 18164)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 3621 (class 2606 OID 18009)
-- Name: businesses businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_pkey PRIMARY KEY (id);


--
-- TOC entry 3612 (class 2606 OID 17963)
-- Name: cooperatives cooperatives_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cooperatives
    ADD CONSTRAINT cooperatives_pkey PRIMARY KEY (id);


--
-- TOC entry 3614 (class 2606 OID 17965)
-- Name: cooperatives cooperatives_registration_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cooperatives
    ADD CONSTRAINT cooperatives_registration_number_key UNIQUE (registration_number);


--
-- TOC entry 3701 (class 2606 OID 24760)
-- Name: idempotency_keys idempotency_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.idempotency_keys
    ADD CONSTRAINT idempotency_keys_pkey PRIMARY KEY (id);


--
-- TOC entry 3699 (class 2606 OID 24747)
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- TOC entry 3681 (class 2606 OID 18126)
-- Name: investment_returns investment_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT investment_returns_pkey PRIMARY KEY (id);


--
-- TOC entry 3683 (class 2606 OID 18128)
-- Name: investment_returns investment_returns_transaction_ref_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT investment_returns_transaction_ref_key UNIQUE (transaction_ref);


--
-- TOC entry 3663 (class 2606 OID 18075)
-- Name: investments investments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_pkey PRIMARY KEY (id);


--
-- TOC entry 3665 (class 2606 OID 18077)
-- Name: investments investments_transaction_ref_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_transaction_ref_key UNIQUE (transaction_ref);


--
-- TOC entry 3673 (class 2606 OID 18108)
-- Name: profit_distributions profit_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profit_distributions
    ADD CONSTRAINT profit_distributions_pkey PRIMARY KEY (id);


--
-- TOC entry 3655 (class 2606 OID 18048)
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- TOC entry 3685 (class 2606 OID 18130)
-- Name: investment_returns unique_investment_distribution; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT unique_investment_distribution UNIQUE (investment_id, distribution_id);


--
-- TOC entry 3667 (class 2606 OID 18079)
-- Name: investments unique_investor_project; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT unique_investor_project UNIQUE (project_id, investor_id);


--
-- TOC entry 3608 (class 2606 OID 17948)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3610 (class 2606 OID 17986)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3688 (class 1259 OID 18169)
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at DESC);


--
-- TOC entry 3689 (class 1259 OID 18166)
-- Name: idx_audit_logs_entity_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_entity_id ON public.audit_logs USING btree (entity_id);


--
-- TOC entry 3690 (class 1259 OID 18171)
-- Name: idx_audit_logs_entity_operation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_entity_operation ON public.audit_logs USING btree (entity_type, entity_id, operation);


--
-- TOC entry 3691 (class 1259 OID 18165)
-- Name: idx_audit_logs_entity_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_entity_type ON public.audit_logs USING btree (entity_type);


--
-- TOC entry 3692 (class 1259 OID 18168)
-- Name: idx_audit_logs_operation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_operation ON public.audit_logs USING btree (operation);


--
-- TOC entry 3693 (class 1259 OID 18170)
-- Name: idx_audit_logs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_status ON public.audit_logs USING btree (status);


--
-- TOC entry 3694 (class 1259 OID 18167)
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- TOC entry 3695 (class 1259 OID 18172)
-- Name: idx_audit_logs_user_operation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user_operation ON public.audit_logs USING btree (user_id, operation, created_at DESC);


--
-- TOC entry 3622 (class 1259 OID 18022)
-- Name: idx_businesses_approval_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_approval_status ON public.businesses USING btree (approval_status);


--
-- TOC entry 3623 (class 1259 OID 24633)
-- Name: idx_businesses_approved_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_approved_at ON public.businesses USING btree (approved_at);


--
-- TOC entry 3624 (class 1259 OID 24632)
-- Name: idx_businesses_approved_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_approved_by ON public.businesses USING btree (approved_by);


--
-- TOC entry 3625 (class 1259 OID 18023)
-- Name: idx_businesses_business_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_business_type ON public.businesses USING btree (business_type);


--
-- TOC entry 3626 (class 1259 OID 18021)
-- Name: idx_businesses_cooperative_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_cooperative_id ON public.businesses USING btree (cooperative_id);


--
-- TOC entry 3627 (class 1259 OID 18025)
-- Name: idx_businesses_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_created_at ON public.businesses USING btree (created_at);


--
-- TOC entry 3628 (class 1259 OID 24631)
-- Name: idx_businesses_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_email ON public.businesses USING btree (email);


--
-- TOC entry 3629 (class 1259 OID 24629)
-- Name: idx_businesses_industry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_industry ON public.businesses USING btree (industry);


--
-- TOC entry 3630 (class 1259 OID 18024)
-- Name: idx_businesses_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_is_active ON public.businesses USING btree (is_active);


--
-- TOC entry 3631 (class 1259 OID 24733)
-- Name: idx_businesses_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_name ON public.businesses USING btree (name);


--
-- TOC entry 3632 (class 1259 OID 24734)
-- Name: idx_businesses_name_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_name_type ON public.businesses USING btree (name, business_type);


--
-- TOC entry 3633 (class 1259 OID 18020)
-- Name: idx_businesses_owner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_owner_id ON public.businesses USING btree (owner_id);


--
-- TOC entry 3634 (class 1259 OID 24628)
-- Name: idx_businesses_registration_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_registration_number ON public.businesses USING btree (registration_number);


--
-- TOC entry 3635 (class 1259 OID 24630)
-- Name: idx_businesses_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_status ON public.businesses USING btree (status);


--
-- TOC entry 3615 (class 1259 OID 17968)
-- Name: idx_cooperatives_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_created_at ON public.cooperatives USING btree (created_at);


--
-- TOC entry 3616 (class 1259 OID 17969)
-- Name: idx_cooperatives_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_email ON public.cooperatives USING btree (email);


--
-- TOC entry 3617 (class 1259 OID 17967)
-- Name: idx_cooperatives_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_is_active ON public.cooperatives USING btree (is_active);


--
-- TOC entry 3618 (class 1259 OID 24729)
-- Name: idx_cooperatives_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_name ON public.cooperatives USING btree (name);


--
-- TOC entry 3619 (class 1259 OID 17966)
-- Name: idx_cooperatives_registration_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_registration_number ON public.cooperatives USING btree (registration_number);


--
-- TOC entry 3702 (class 1259 OID 24762)
-- Name: idx_idempotency_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_expires_at ON public.idempotency_keys USING btree (expires_at);


--
-- TOC entry 3703 (class 1259 OID 24763)
-- Name: idx_idempotency_sequence; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_sequence ON public.idempotency_keys USING btree (sequence_number);


--
-- TOC entry 3704 (class 1259 OID 24764)
-- Name: idx_idempotency_table_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_table_name ON public.idempotency_keys USING btree (table_name);


--
-- TOC entry 3705 (class 1259 OID 24761)
-- Name: idx_idempotency_user_endpoint; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_user_endpoint ON public.idempotency_keys USING btree (user_id, endpoint);


--
-- TOC entry 3696 (class 1259 OID 24749)
-- Name: idx_images_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_images_created_at ON public.images USING btree (created_at);


--
-- TOC entry 3697 (class 1259 OID 24748)
-- Name: idx_images_used_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_images_used_by ON public.images USING btree (used_by);


--
-- TOC entry 3674 (class 1259 OID 18150)
-- Name: idx_investment_returns_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_created_at ON public.investment_returns USING btree (created_at);


--
-- TOC entry 3675 (class 1259 OID 18146)
-- Name: idx_investment_returns_distribution_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_distribution_id ON public.investment_returns USING btree (distribution_id);


--
-- TOC entry 3676 (class 1259 OID 18145)
-- Name: idx_investment_returns_investment_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_investment_id ON public.investment_returns USING btree (investment_id);


--
-- TOC entry 3677 (class 1259 OID 18148)
-- Name: idx_investment_returns_payment_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_payment_date ON public.investment_returns USING btree (payment_date);


--
-- TOC entry 3678 (class 1259 OID 18147)
-- Name: idx_investment_returns_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_status ON public.investment_returns USING btree (status);


--
-- TOC entry 3679 (class 1259 OID 18149)
-- Name: idx_investment_returns_transaction_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_transaction_ref ON public.investment_returns USING btree (transaction_ref);


--
-- TOC entry 3656 (class 1259 OID 18095)
-- Name: idx_investments_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_created_at ON public.investments USING btree (created_at);


--
-- TOC entry 3657 (class 1259 OID 18093)
-- Name: idx_investments_investment_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_investment_date ON public.investments USING btree (investment_date);


--
-- TOC entry 3658 (class 1259 OID 18091)
-- Name: idx_investments_investor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_investor_id ON public.investments USING btree (investor_id);


--
-- TOC entry 3659 (class 1259 OID 18090)
-- Name: idx_investments_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_project_id ON public.investments USING btree (project_id);


--
-- TOC entry 3660 (class 1259 OID 18092)
-- Name: idx_investments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_status ON public.investments USING btree (status);


--
-- TOC entry 3661 (class 1259 OID 18094)
-- Name: idx_investments_transaction_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_transaction_ref ON public.investments USING btree (transaction_ref);


--
-- TOC entry 3668 (class 1259 OID 18144)
-- Name: idx_profit_distributions_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_created_at ON public.profit_distributions USING btree (created_at);


--
-- TOC entry 3669 (class 1259 OID 18143)
-- Name: idx_profit_distributions_distribution_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_distribution_date ON public.profit_distributions USING btree (distribution_date);


--
-- TOC entry 3670 (class 1259 OID 18141)
-- Name: idx_profit_distributions_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_project_id ON public.profit_distributions USING btree (project_id);


--
-- TOC entry 3671 (class 1259 OID 18142)
-- Name: idx_profit_distributions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_status ON public.profit_distributions USING btree (status);


--
-- TOC entry 3636 (class 1259 OID 32858)
-- Name: idx_projects_approval_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_approval_status ON public.projects USING btree (approval_status);


--
-- TOC entry 3637 (class 1259 OID 32864)
-- Name: idx_projects_approved_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_approved_by ON public.projects USING btree (approved_by);


--
-- TOC entry 3638 (class 1259 OID 18054)
-- Name: idx_projects_business_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_business_id ON public.projects USING btree (business_id);


--
-- TOC entry 3639 (class 1259 OID 32816)
-- Name: idx_projects_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_category ON public.projects USING btree (category);


--
-- TOC entry 3640 (class 1259 OID 32818)
-- Name: idx_projects_cooperative_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_cooperative_id ON public.projects USING btree (cooperative_id);


--
-- TOC entry 3641 (class 1259 OID 18058)
-- Name: idx_projects_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_created_at ON public.projects USING btree (created_at);


--
-- TOC entry 3642 (class 1259 OID 18057)
-- Name: idx_projects_funding_deadline; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_funding_deadline ON public.projects USING btree (funding_deadline);


--
-- TOC entry 3643 (class 1259 OID 18059)
-- Name: idx_projects_funding_goal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_funding_goal ON public.projects USING btree (funding_goal);


--
-- TOC entry 3644 (class 1259 OID 32815)
-- Name: idx_projects_investment_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_investment_period ON public.projects USING btree (investment_period);


--
-- TOC entry 3645 (class 1259 OID 32817)
-- Name: idx_projects_owner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_owner_id ON public.projects USING btree (owner_id);


--
-- TOC entry 3646 (class 1259 OID 18056)
-- Name: idx_projects_project_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_project_type ON public.projects USING btree (project_type);


--
-- TOC entry 3647 (class 1259 OID 32865)
-- Name: idx_projects_rejected_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_rejected_by ON public.projects USING btree (rejected_by);


--
-- TOC entry 3648 (class 1259 OID 32814)
-- Name: idx_projects_risk_level; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_risk_level ON public.projects USING btree (risk_level);


--
-- TOC entry 3649 (class 1259 OID 32819)
-- Name: idx_projects_start_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_start_date ON public.projects USING btree (start_date);


--
-- TOC entry 3650 (class 1259 OID 18055)
-- Name: idx_projects_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_status ON public.projects USING btree (status);


--
-- TOC entry 3651 (class 1259 OID 24737)
-- Name: idx_projects_status_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_status_type ON public.projects USING btree (status, project_type);


--
-- TOC entry 3652 (class 1259 OID 24735)
-- Name: idx_projects_title; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_title ON public.projects USING btree (title);


--
-- TOC entry 3653 (class 1259 OID 24736)
-- Name: idx_projects_title_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_title_type ON public.projects USING btree (title, project_type);


--
-- TOC entry 3597 (class 1259 OID 17992)
-- Name: idx_users_cooperative_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_cooperative_id ON public.users USING btree (cooperative_id);


--
-- TOC entry 3598 (class 1259 OID 17951)
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- TOC entry 3599 (class 1259 OID 17949)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 3600 (class 1259 OID 17950)
-- Name: idx_users_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_is_active ON public.users USING btree (is_active);


--
-- TOC entry 3601 (class 1259 OID 17994)
-- Name: idx_users_kyc_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_kyc_status ON public.users USING btree (kyc_status);


--
-- TOC entry 3602 (class 1259 OID 41070)
-- Name: idx_users_membership_payment_proof; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_membership_payment_proof ON public.users USING btree (membership_payment_proof) WHERE (membership_payment_proof IS NOT NULL);


--
-- TOC entry 3603 (class 1259 OID 24728)
-- Name: idx_users_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_name ON public.users USING btree (name);


--
-- TOC entry 3604 (class 1259 OID 24731)
-- Name: idx_users_name_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_name_search ON public.users USING btree (name);


--
-- TOC entry 3605 (class 1259 OID 24732)
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone);


--
-- TOC entry 3606 (class 1259 OID 17993)
-- Name: idx_users_roles; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_roles ON public.users USING gin (roles);


--
-- TOC entry 3720 (class 2620 OID 24751)
-- Name: images trigger_update_images_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_images_updated_at BEFORE UPDATE ON public.images FOR EACH ROW EXECUTE FUNCTION public.update_images_updated_at();


--
-- TOC entry 3715 (class 2620 OID 18026)
-- Name: businesses update_businesses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_businesses_updated_at BEFORE UPDATE ON public.businesses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3714 (class 2620 OID 17971)
-- Name: cooperatives update_cooperatives_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_cooperatives_updated_at BEFORE UPDATE ON public.cooperatives FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3719 (class 2620 OID 18152)
-- Name: investment_returns update_investment_returns_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_investment_returns_updated_at BEFORE UPDATE ON public.investment_returns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3717 (class 2620 OID 18096)
-- Name: investments update_investments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_investments_updated_at BEFORE UPDATE ON public.investments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3718 (class 2620 OID 18151)
-- Name: profit_distributions update_profit_distributions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_profit_distributions_updated_at BEFORE UPDATE ON public.profit_distributions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3716 (class 2620 OID 18060)
-- Name: projects update_projects_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3713 (class 2620 OID 17995)
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3711 (class 2606 OID 18136)
-- Name: investment_returns fk_investment_returns_distribution; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT fk_investment_returns_distribution FOREIGN KEY (distribution_id) REFERENCES public.profit_distributions(id) ON DELETE CASCADE;


--
-- TOC entry 3712 (class 2606 OID 18131)
-- Name: investment_returns fk_investment_returns_investment; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT fk_investment_returns_investment FOREIGN KEY (investment_id) REFERENCES public.investments(id) ON DELETE CASCADE;


--
-- TOC entry 3708 (class 2606 OID 18085)
-- Name: investments fk_investments_investor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT fk_investments_investor FOREIGN KEY (investor_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3709 (class 2606 OID 18080)
-- Name: investments fk_investments_project; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT fk_investments_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- TOC entry 3710 (class 2606 OID 18109)
-- Name: profit_distributions fk_profit_distributions_project; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profit_distributions
    ADD CONSTRAINT fk_profit_distributions_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- TOC entry 3706 (class 2606 OID 17987)
-- Name: users fk_users_cooperative; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_cooperative FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE SET NULL;


--
-- TOC entry 3707 (class 2606 OID 32859)
-- Name: projects projects_rejected_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.users(id);


-- Completed on 2025-12-02 08:09:10 WIB

--
-- PostgreSQL database dump complete
--

