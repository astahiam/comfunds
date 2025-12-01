--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Postgres.app)
-- Dumped by pg_dump version 16.3 (Postgres.app)

-- Started on 2025-10-19 22:16:23 WIB

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
-- TOC entry 3789 (class 0 OID 17655)
-- Dependencies: 224
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.audit_logs DISABLE TRIGGER ALL;

COPY public.audit_logs (id, entity_type, entity_id, operation, user_id, ip_address, user_agent, changes, old_values, new_values, reason, status, error_msg, created_at) FROM stdin;
\.


ALTER TABLE public.audit_logs ENABLE TRIGGER ALL;

--
-- TOC entry 3783 (class 0 OID 17498)
-- Dependencies: 218
-- Data for Name: businesses; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.businesses DISABLE TRIGGER ALL;

COPY public.businesses (id, name, business_type, description, owner_id, cooperative_id, registration_documents, approval_status, is_active, created_at, updated_at, business_image, registration_number, tax_id, legal_structure, industry, sector, address, phone, email, website, established_date, employee_count, annual_revenue, currency, bank_account, business_license, documents, status, approved_by, approved_at, rejection_reason, metadata, performance_metrics, compliance_status) FROM stdin;
ecb3d125-4754-4602-bd4e-83b0420d095a	Test Technology Business	technology	A test technology business for demo purposes	7a5327fe-7ac2-45ff-8e9f-3a6a9f006f71	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-10-05 10:19:46.520894+07	2025-10-11 11:04:14.551847+07	\N	TEST-001		PT	Software Development		Jl. Test Business No. 123, Jakarta	+62-123-456-789	test@business.com	https://testbusiness.com	2020-01-01	10	1000000000.00	IDR	1234567890	LIC-001	null	draft	\N	\N	\N	null	null	null
\.


ALTER TABLE public.businesses ENABLE TRIGGER ALL;

--
-- TOC entry 3782 (class 0 OID 17454)
-- Dependencies: 217
-- Data for Name: cooperatives; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.cooperatives DISABLE TRIGGER ALL;

COPY public.cooperatives (id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at, cooperative_image) FROM stdin;
5abbf3b6-d084-4371-8043-7d25e8117ba7	Cooperative 0	COOP-2024-000-7000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-22 16:55:09.106425+07	2025-08-22 16:55:09.106425+07	\N
49e68912-9fb8-4b70-8c5c-52fd11f51942	Cooperative 4	COOP-2024-004-7000	Address 4	+12345670004	coop4@example.com	1234567894	{}	t	2025-08-22 16:55:09.116332+07	2025-08-22 16:55:09.116332+07	\N
f22830a8-d381-4b91-9e5d-e75c9a3768bd	Cooperative 8	COOP-2024-008-4000	Address 8	+12345670008	coop8@example.com	1234567898	{}	t	2025-08-22 16:55:09.119717+07	2025-08-22 16:55:09.119717+07	\N
25098046-ca67-4336-a29b-ec0da66694be	Cooperative 12	COOP-2024-012-8000	Address 12	+12345670012	coop12@example.com	12345678912	{}	t	2025-08-22 16:55:09.121981+07	2025-08-22 16:55:09.121981+07	\N
071b1ff3-153f-4bd9-8821-2fd54108228b	Cooperative 16	COOP-2024-016-4000	Address 16	+12345670016	coop16@example.com	12345678916	{}	t	2025-08-22 16:55:09.125467+07	2025-08-22 16:55:09.125467+07	\N
906eef7a-a68c-45ae-b8bf-9646ad356683	Cooperative 0	COOP-2024-000-5000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-22 16:55:46.025284+07	2025-08-22 16:55:46.025285+07	\N
bb2ebdb9-2146-414a-b1a6-bcfe0509bdd0	Cooperative 0	COOP-2024-000-1755856577349301000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-22 16:56:17.349305+07	2025-08-22 16:56:17.349305+07	\N
903ccb54-9314-4ae1-a560-161d54899348	Cooperative 4	COOP-2024-004-1755856577352431000	Address 4	+12345670004	coop4@example.com	1234567894	{}	t	2025-08-22 16:56:17.352433+07	2025-08-22 16:56:17.352433+07	\N
fdb187e7-1b89-41fa-ad2b-3828317a30d9	Cooperative 8	COOP-2024-008-1755856577358228000	Address 8	+12345670008	coop8@example.com	1234567898	{}	t	2025-08-22 16:56:17.358233+07	2025-08-22 16:56:17.358234+07	\N
404cf731-8ff1-4d55-a7cd-d57ba4432ff6	Cooperative 12	COOP-2024-012-1755856577361242000	Address 12	+12345670012	coop12@example.com	12345678912	{}	t	2025-08-22 16:56:17.361246+07	2025-08-22 16:56:17.361246+07	\N
68289f71-26d9-45af-b804-09bebbf6d006	Cooperative 16	COOP-2024-016-1755856577364311000	Address 16	+12345670016	coop16@example.com	12345678916	{}	t	2025-08-22 16:56:17.364313+07	2025-08-22 16:56:17.364313+07	\N
9d25045c-034c-484f-8a93-f19709b0ba03	Cooperative 0	COOP-2024-000-1755858945243849000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-22 17:35:45.243852+07	2025-08-22 17:35:45.243852+07	\N
4ff24bab-774d-40ab-bf42-d49c7c63a52f	Cooperative 4	COOP-2024-004-1755858945248307000	Address 4	+12345670004	coop4@example.com	1234567894	{}	t	2025-08-22 17:35:45.248309+07	2025-08-22 17:35:45.24831+07	\N
674c7303-1a7d-4a99-bde1-bf0b31072f37	Cooperative 8	COOP-2024-008-1755858945249868000	Address 8	+12345670008	coop8@example.com	1234567898	{}	t	2025-08-22 17:35:45.24987+07	2025-08-22 17:35:45.24987+07	\N
2e2c130d-65c5-4e2c-a445-6d5a4dadf0fb	Cooperative 12	COOP-2024-012-1755858945251226000	Address 12	+12345670012	coop12@example.com	12345678912	{}	t	2025-08-22 17:35:45.251227+07	2025-08-22 17:35:45.251227+07	\N
a1bfc08d-2cf5-4852-aba2-c0aee102bcd4	Cooperative 16	COOP-2024-016-1755858945252603000	Address 16	+12345670016	coop16@example.com	12345678916	{}	t	2025-08-22 17:35:45.252605+07	2025-08-22 17:35:45.252605+07	\N
18e1e616-de47-45b5-8924-e42776132df7	Cooperative 0	COOP-2024-000-1756473775208547000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-29 20:22:55.208556+07	2025-08-29 20:22:55.208556+07	\N
f2332ab6-168a-4cfe-bda4-560a337546f4	Cooperative 4	COOP-2024-004-1756473775216851000	Address 4	+12345670004	coop4@example.com	1234567894	{}	t	2025-08-29 20:22:55.216854+07	2025-08-29 20:22:55.216854+07	\N
1e86fd68-b69b-4edf-afa4-4275db7f8af2	Cooperative 8	COOP-2024-008-1756473775218964000	Address 8	+12345670008	coop8@example.com	1234567898	{}	t	2025-08-29 20:22:55.218984+07	2025-08-29 20:22:55.218984+07	\N
7d80d0ca-5c78-4cf5-a6db-8483193c8d54	Cooperative 12	COOP-2024-012-1756473775221666000	Address 12	+12345670012	coop12@example.com	12345678912	{}	t	2025-08-29 20:22:55.221668+07	2025-08-29 20:22:55.221668+07	\N
c1705843-9049-4841-a19d-316cd14d76a8	Cooperative 16	COOP-2024-016-1756473775223375000	Address 16	+12345670016	coop16@example.com	12345678916	{}	t	2025-08-29 20:22:55.223376+07	2025-08-29 20:22:55.223377+07	\N
1394e94f-f64f-4fa5-998c-78969449794b	Cooperative 0	COOP-2024-000-1756475953201256000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-29 20:59:13.201259+07	2025-08-29 20:59:13.201259+07	\N
692b53f9-424e-40bf-9263-84da2edf93ec	Cooperative 4	COOP-2024-004-1756475953209043000	Address 4	+12345670004	coop4@example.com	1234567894	{}	t	2025-08-29 20:59:13.209046+07	2025-08-29 20:59:13.209046+07	\N
6377ccc9-3edf-44c3-8891-66b23a569d91	Cooperative 8	COOP-2024-008-1756475953212082000	Address 8	+12345670008	coop8@example.com	1234567898	{}	t	2025-08-29 20:59:13.212085+07	2025-08-29 20:59:13.212085+07	\N
b5ac8fdb-3f13-4d9c-85bc-f4cf37c2916b	Cooperative 12	COOP-2024-012-1756475953214479000	Address 12	+12345670012	coop12@example.com	12345678912	{}	t	2025-08-29 20:59:13.214481+07	2025-08-29 20:59:13.214481+07	\N
ec27f643-4825-4c72-9814-d45bd1b8d24f	Cooperative 16	COOP-2024-016-1756475953216101000	Address 16	+12345670016	coop16@example.com	12345678916	{}	t	2025-08-29 20:59:13.216103+07	2025-08-29 20:59:13.216103+07	\N
947fee1b-db74-4d99-bab8-72c70156aaff	Cooperative 0	COOP-2024-000-1756479580164211000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-29 21:59:40.164217+07	2025-08-29 21:59:40.164217+07	\N
dfed8953-aa8a-483c-9af6-8e8023bd4e41	Cooperative 4	COOP-2024-004-1756479580178890000	Address 4	+12345670004	coop4@example.com	1234567894	{}	t	2025-08-29 21:59:40.178893+07	2025-08-29 21:59:40.178893+07	\N
289a7005-29a0-4d9b-8546-b87eddc3d2af	Cooperative 8	COOP-2024-008-1756479580195416000	Address 8	+12345670008	coop8@example.com	1234567898	{}	t	2025-08-29 21:59:40.195443+07	2025-08-29 21:59:40.195443+07	\N
aefb5908-28cc-4fa1-83e8-b4f6a2363db0	Cooperative 12	COOP-2024-012-1756479580206767000	Address 12	+12345670012	coop12@example.com	12345678912	{}	t	2025-08-29 21:59:40.206771+07	2025-08-29 21:59:40.206771+07	\N
949e0bca-8626-449a-a37e-dba01278082b	Cooperative 16	COOP-2024-016-1756479580250674000	Address 16	+12345670016	coop16@example.com	12345678916	{}	t	2025-08-29 21:59:40.250677+07	2025-08-29 21:59:40.250678+07	\N
3fc8dfed-aa7a-455c-aaa9-531bfd54ebdd	Cooperative 0	COOP-2024-000-1756479720901739000	Address 0	+12345670000	coop0@example.com	1234567890	{}	t	2025-08-29 22:02:00.901742+07	2025-08-29 22:02:00.901742+07	\N
20fe568d-0cea-46ec-9127-2a5474af9813	Cooperative 4	COOP-2024-004-1756479720904626000	Address 4	+12345670004	coop4@example.com	1234567894	{}	t	2025-08-29 22:02:00.904628+07	2025-08-29 22:02:00.904628+07	\N
5e539cf3-3b0a-42c8-82c1-1e46daec6e2a	Cooperative 8	COOP-2024-008-1756479720906833000	Address 8	+12345670008	coop8@example.com	1234567898	{}	t	2025-08-29 22:02:00.906836+07	2025-08-29 22:02:00.906836+07	\N
fbd4ba5a-d0e3-4b74-81a6-87135cc8e802	Cooperative 12	COOP-2024-012-1756479720909120000	Address 12	+12345670012	coop12@example.com	12345678912	{}	t	2025-08-29 22:02:00.909122+07	2025-08-29 22:02:00.909122+07	\N
1d54d00d-52e3-490b-8fbb-50d79ff957e5	Cooperative 16	COOP-2024-016-1756479720910794000	Address 16	+12345670016	coop16@example.com	12345678916	{}	t	2025-08-29 22:02:00.910795+07	2025-08-29 22:02:00.910795+07	\N
1ded8fec-02b6-4aa4-8726-9defa43202c3	Hajifund	REG-001-2025	Jl. Hajifund No. 1, Jakarta	+62-21-12345678	info@hajifund.coop	1234567890	null	t	2025-08-31 12:20:21.858409+07	2025-08-31 12:20:21.858409+07	\N
5fa79667-1d5d-4f1d-a8c2-0f7ed0f64744	Sidana	REG-002-2025	Jl. Sidana No. 2, Bandung	+62-22-87654321	info@sidana.coop	0987654321	null	t	2025-08-31 12:20:22.501405+07	2025-08-31 12:20:22.501405+07	\N
550e8400-e29b-41d4-a716-446655440001	Koperasi Haji	KH-001-2024	Jl. Masjidil Haram No. 123, Jakarta Pusat	+62-21-12345678	info@koperasihaji.id	1234567890	{"platform_fee": 5, "default_business_share": 30, "default_investor_share": 70}	t	2025-09-19 21:28:11.447736+07	2025-09-19 21:37:14.742472+07	\N
550e8400-e29b-41d4-a716-446655440002	Koperasi SIDANA	SIDANA-002-2024	Jl. Simpan Pinjam No. 456, Jakarta Selatan	+62-21-87654321	info@koperasisidana.id	0987654321	{"platform_fee": 3, "default_business_share": 25, "default_investor_share": 75}	t	2025-09-19 21:28:11.447736+07	2025-09-19 21:37:14.742472+07	\N
\.


ALTER TABLE public.cooperatives ENABLE TRIGGER ALL;

--
-- TOC entry 3791 (class 0 OID 24676)
-- Dependencies: 226
-- Data for Name: idempotency_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.idempotency_keys DISABLE TRIGGER ALL;

COPY public.idempotency_keys (id, user_id, endpoint, request_hash, response_data, status, created_at, expires_at, sequence_number, table_name, random_suffix) FROM stdin;
\.


ALTER TABLE public.idempotency_keys ENABLE TRIGGER ALL;

--
-- TOC entry 3790 (class 0 OID 24662)
-- Dependencies: 225
-- Data for Name: images; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.images DISABLE TRIGGER ALL;

COPY public.images (id, image_url, image_name, used_by, image_size, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.images ENABLE TRIGGER ALL;

--
-- TOC entry 3781 (class 0 OID 17438)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.users DISABLE TRIGGER ALL;

COPY public.users (email, name, password, phone, address, is_active, created_at, updated_at, id, cooperative_id, roles, kyc_status, user_profile_image) FROM stdin;
user-4-f3828800@example.com	User 4	hashedpassword	\N	\N	t	2025-08-22 16:55:09.044396+07	2025-08-22 16:55:09.044396+07	f3828800-930a-4769-915a-e6f5a042987a	\N	["guest"]	pending	\N
user-5-68afbd56@example.com	User 5	hashedpassword	\N	\N	t	2025-08-22 16:55:09.047386+07	2025-08-22 16:55:09.047386+07	68afbd56-9d1f-471e-a1d5-6de3df36147e	\N	["guest"]	pending	\N
user-7-7ee3828d@example.com	User 7	hashedpassword	\N	\N	t	2025-08-22 16:55:09.048995+07	2025-08-22 16:55:09.048995+07	7ee3828d-ea5a-429a-90ed-b739bbec38a8	\N	["guest"]	pending	\N
user-8-44a15334@example.com	User 8	hashedpassword	\N	\N	t	2025-08-22 16:55:09.049841+07	2025-08-22 16:55:09.049841+07	44a15334-c145-4616-a778-d8a67999131e	\N	["guest"]	pending	\N
user-10-c3814415@example.com	User 10	hashedpassword	\N	\N	t	2025-08-22 16:55:09.051289+07	2025-08-22 16:55:09.051289+07	c3814415-ba83-4cad-bfb7-2041b4f7c2e5	\N	["guest"]	pending	\N
user-12-11a48898@example.com	User 12	hashedpassword	\N	\N	t	2025-08-22 16:55:09.052522+07	2025-08-22 16:55:09.052522+07	11a48898-9a99-4625-aba7-475a515473bc	\N	["guest"]	pending	\N
user-13-db512831@example.com	User 13	hashedpassword	\N	\N	t	2025-08-22 16:55:09.053023+07	2025-08-22 16:55:09.053023+07	db512831-b29f-49da-9d9c-07b171f1a0f6	\N	["guest"]	pending	\N
user-19-efe71bee@example.com	User 19	hashedpassword	\N	\N	t	2025-08-22 16:55:09.057092+07	2025-08-22 16:55:09.057093+07	efe71bee-732e-4550-b6c5-7bcc8116553f	\N	["guest"]	pending	\N
user-23-991007ee@example.com	User 23	hashedpassword	\N	\N	t	2025-08-22 16:55:09.06044+07	2025-08-22 16:55:09.06044+07	991007ee-87f1-4b0c-b398-c2ecb2cfbc23	\N	["guest"]	pending	\N
user-30-10457934@example.com	User 30	hashedpassword	\N	\N	t	2025-08-22 16:55:09.064368+07	2025-08-22 16:55:09.064368+07	10457934-8683-48b3-9d5b-54f48eac5d4d	\N	["guest"]	pending	\N
user-31-a7abd47d@example.com	User 31	hashedpassword	\N	\N	t	2025-08-22 16:55:09.064957+07	2025-08-22 16:55:09.064957+07	a7abd47d-bf8d-40f8-bd8b-dc63b98c9768	\N	["guest"]	pending	\N
user-42-52478e53@example.com	User 42	hashedpassword	\N	\N	t	2025-08-22 16:55:09.072645+07	2025-08-22 16:55:09.072646+07	52478e53-0ca3-4979-bfc4-58421f4762a6	\N	["guest"]	pending	\N
user-43-a60ddfbc@example.com	User 43	hashedpassword	\N	\N	t	2025-08-22 16:55:09.073602+07	2025-08-22 16:55:09.073602+07	a60ddfbc-5da2-420f-bfbe-767aa26d70f4	\N	["guest"]	pending	\N
user-45-a22cc37c@example.com	User 45	hashedpassword	\N	\N	t	2025-08-22 16:55:09.075403+07	2025-08-22 16:55:09.075403+07	a22cc37c-9f1c-4abb-aaa4-5837f2130a4b	\N	["guest"]	pending	\N
user-46-b520f78b@example.com	User 46	hashedpassword	\N	\N	t	2025-08-22 16:55:09.076247+07	2025-08-22 16:55:09.076247+07	b520f78b-a0ba-446b-8425-b1028e41c5f0	\N	["guest"]	pending	\N
user-48-7bdb5115@example.com	User 48	hashedpassword	\N	\N	t	2025-08-22 16:55:09.077605+07	2025-08-22 16:55:09.077606+07	7bdb5115-5d7f-4138-b19c-96c280e971cc	\N	["guest"]	pending	\N
user-49-45bed8c0@example.com	User 49	hashedpassword	\N	\N	t	2025-08-22 16:55:09.078107+07	2025-08-22 16:55:09.078107+07	45bed8c0-0d3a-4dd9-b74a-bb5b022f0c32	\N	["guest"]	pending	\N
user-50-7ced7715@example.com	User 50	hashedpassword	\N	\N	t	2025-08-22 16:55:09.078828+07	2025-08-22 16:55:09.078828+07	7ced7715-3a98-4f12-8d30-2a1a0b382b0f	\N	["guest"]	pending	\N
user-55-51a9f118@example.com	User 55	hashedpassword	\N	\N	t	2025-08-22 16:55:09.081697+07	2025-08-22 16:55:09.081697+07	51a9f118-bbc5-48af-8bda-e4a551c9f595	\N	["guest"]	pending	\N
user-56-b5cec71c@example.com	User 56	hashedpassword	\N	\N	t	2025-08-22 16:55:09.082222+07	2025-08-22 16:55:09.082222+07	b5cec71c-9cd1-4a03-824e-480c0f708d44	\N	["guest"]	pending	\N
user-61-aa53ebb9@example.com	User 61	hashedpassword	\N	\N	t	2025-08-22 16:55:09.084384+07	2025-08-22 16:55:09.084384+07	aa53ebb9-29ec-44e1-8cf9-909faaab73bb	\N	["guest"]	pending	\N
user-69-129bcd63@example.com	User 69	hashedpassword	\N	\N	t	2025-08-22 16:55:09.087201+07	2025-08-22 16:55:09.087201+07	129bcd63-38d8-4e8d-a2ee-95662aa6fcc9	\N	["guest"]	pending	\N
user-72-5f21e7f1@example.com	User 72	hashedpassword	\N	\N	t	2025-08-22 16:55:09.089236+07	2025-08-22 16:55:09.089236+07	5f21e7f1-ba71-4b64-b3f1-1c87b5197f0e	\N	["guest"]	pending	\N
user-82-64fb7fca@example.com	User 82	hashedpassword	\N	\N	t	2025-08-22 16:55:09.095653+07	2025-08-22 16:55:09.095653+07	64fb7fca-14e0-49f0-a680-7d84ef7160c4	\N	["guest"]	pending	\N
user-84-64f61b3d@example.com	User 84	hashedpassword	\N	\N	t	2025-08-22 16:55:09.096599+07	2025-08-22 16:55:09.096599+07	64f61b3d-d27f-4cde-8d6b-6ac7da18edb5	\N	["guest"]	pending	\N
user-87-04e99c92@example.com	User 87	hashedpassword	\N	\N	t	2025-08-22 16:55:09.098274+07	2025-08-22 16:55:09.098275+07	04e99c92-ae22-4066-ad24-f95113e73804	\N	["guest"]	pending	\N
user-96-5701dc11@example.com	User 96	hashedpassword	\N	\N	t	2025-08-22 16:55:09.103243+07	2025-08-22 16:55:09.103243+07	5701dc11-6792-4fba-ba91-52338550ee4e	\N	["guest"]	pending	\N
user-99-e30cd082@example.com	User 99	hashedpassword	\N	\N	t	2025-08-22 16:55:09.105151+07	2025-08-22 16:55:09.105151+07	e30cd082-40a7-43a8-992a-abfa1a813e08	\N	["guest"]	pending	\N
concurrent-user-0-9dd6c81e@example.com	Concurrent User 0	password	\N	\N	t	2025-08-22 16:55:09.326173+07	2025-08-22 16:55:09.326174+07	9dd6c81e-403a-4c8d-9ebd-441a2aca1a19	\N	["guest"]	pending	\N
concurrent-user-4-499b809a@example.com	Concurrent User 4	password	\N	\N	t	2025-08-22 16:55:09.326094+07	2025-08-22 16:55:09.326095+07	499b809a-d802-43ec-9dd4-88d49ca064d0	\N	["guest"]	pending	\N
perf-test-0-831920fe@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:09.466098+07	2025-08-22 16:55:09.466099+07	831920fe-588b-41ca-b3ef-5cc6103473d4	\N	["guest"]	pending	\N
perf-test-1-36d92eaf@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:09.468172+07	2025-08-22 16:55:09.468172+07	36d92eaf-0f59-4550-9db0-1b3b471ac502	\N	["guest"]	pending	\N
perf-test-2-e8e36895@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:09.469027+07	2025-08-22 16:55:09.469027+07	e8e36895-e008-406a-9132-2233b59d58b2	\N	["guest"]	pending	\N
perf-test-3-4b772580@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:09.469549+07	2025-08-22 16:55:09.469549+07	4b772580-9e61-488c-9f5c-a53772633e6a	\N	["guest"]	pending	\N
perf-test-4-0753216e@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:09.470094+07	2025-08-22 16:55:09.470094+07	0753216e-5cc3-4a91-88fc-54be331b7a8d	\N	["guest"]	pending	\N
perf-test-5-79bebaac@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:09.47062+07	2025-08-22 16:55:09.47062+07	79bebaac-8c51-4793-9beb-771c557ceb71	\N	["guest"]	pending	\N
perf-test-6-c0299849@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:09.471098+07	2025-08-22 16:55:09.471098+07	c0299849-5946-4c81-a23c-9ddcc7b5869b	\N	["guest"]	pending	\N
perf-test-7-71576ab3@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:09.47163+07	2025-08-22 16:55:09.47163+07	71576ab3-8539-4180-9a88-37dd5c4df9bc	\N	["guest"]	pending	\N
perf-test-8-38435c2d@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:09.474249+07	2025-08-22 16:55:09.474249+07	38435c2d-a50e-4e7d-94bc-77ae6f6010a3	\N	["guest"]	pending	\N
perf-test-9-48e3f4ca@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:09.474993+07	2025-08-22 16:55:09.474994+07	48e3f4ca-e1b2-4526-b36f-f36db51db542	\N	["guest"]	pending	\N
perf-test-10-aeeaa5a3@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:09.475683+07	2025-08-22 16:55:09.475684+07	aeeaa5a3-68d5-4229-a2e1-8b4d91fc1586	\N	["guest"]	pending	\N
perf-test-11-2a5d5943@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:09.476295+07	2025-08-22 16:55:09.476296+07	2a5d5943-21e9-4ff5-a2f3-83638da4e812	\N	["guest"]	pending	\N
perf-test-12-68086906@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:09.476789+07	2025-08-22 16:55:09.47679+07	68086906-d208-47b4-8902-eb5fc8541046	\N	["guest"]	pending	\N
perf-test-13-0414d734@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:09.477151+07	2025-08-22 16:55:09.477151+07	0414d734-3208-405a-b7c1-cb8b9299044c	\N	["guest"]	pending	\N
perf-test-14-16531cd2@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:09.477531+07	2025-08-22 16:55:09.477531+07	16531cd2-6bf7-4a76-879a-fd0e21f88ebb	\N	["guest"]	pending	\N
perf-test-15-f2f34be9@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:09.477881+07	2025-08-22 16:55:09.477881+07	f2f34be9-5bcd-480d-9ff8-f48d8d0f2041	\N	["guest"]	pending	\N
perf-test-16-5c71f0a4@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:09.478278+07	2025-08-22 16:55:09.478278+07	5c71f0a4-c1dc-46f9-91e3-b4d868cf9ab0	\N	["guest"]	pending	\N
perf-test-17-17591c29@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:09.478858+07	2025-08-22 16:55:09.478858+07	17591c29-ee8e-493a-8641-aadf91b1b541	\N	["guest"]	pending	\N
perf-test-18-960bea81@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:09.479355+07	2025-08-22 16:55:09.479355+07	960bea81-7e33-416e-94c0-81492021d2e7	\N	["guest"]	pending	\N
perf-test-19-801a4e8f@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:09.479817+07	2025-08-22 16:55:09.479817+07	801a4e8f-5d04-4644-bc69-f86b10f433fa	\N	["guest"]	pending	\N
perf-test-20-2014ae81@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:09.480279+07	2025-08-22 16:55:09.480279+07	2014ae81-6d0f-48c0-8d10-50d9ccbfde25	\N	["guest"]	pending	\N
perf-test-21-6cc0b22b@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:09.480886+07	2025-08-22 16:55:09.480886+07	6cc0b22b-ef40-4f83-802e-d7b6f8f58666	\N	["guest"]	pending	\N
perf-test-22-c70ba980@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:09.481275+07	2025-08-22 16:55:09.481276+07	c70ba980-2086-46c5-b40f-a681707b740e	\N	["guest"]	pending	\N
perf-test-23-a7e075c0@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:09.481784+07	2025-08-22 16:55:09.481785+07	a7e075c0-958d-4620-810d-fd8878cbf721	\N	["guest"]	pending	\N
perf-test-24-dfbb8df2@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:09.483304+07	2025-08-22 16:55:09.483304+07	dfbb8df2-1c5c-4f62-9434-ac749ff6cf49	\N	["guest"]	pending	\N
perf-test-25-1aec59e0@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:09.483877+07	2025-08-22 16:55:09.483877+07	1aec59e0-5d2f-4f6e-b686-263cf0d90230	\N	["guest"]	pending	\N
perf-test-26-c2e5083d@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:09.484308+07	2025-08-22 16:55:09.484308+07	c2e5083d-bd3b-42e4-82c5-8abd0d7799f7	\N	["guest"]	pending	\N
perf-test-27-a9d93ccd@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:09.484706+07	2025-08-22 16:55:09.484706+07	a9d93ccd-f4de-463e-a31e-609752daa8fe	\N	["guest"]	pending	\N
perf-test-28-405d6739@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:09.485059+07	2025-08-22 16:55:09.485059+07	405d6739-768c-40e4-998e-be07ae19396b	\N	["guest"]	pending	\N
perf-test-29-b28a9a45@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:09.485418+07	2025-08-22 16:55:09.485418+07	b28a9a45-7ad8-4ebc-9ce9-7a125c833340	\N	["guest"]	pending	\N
perf-test-30-bf856be0@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:09.485762+07	2025-08-22 16:55:09.485762+07	bf856be0-5189-4575-8940-a18ea7bb1607	\N	["guest"]	pending	\N
perf-test-31-e5a0f724@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:09.486108+07	2025-08-22 16:55:09.486109+07	e5a0f724-fec0-4118-858a-50143d682355	\N	["guest"]	pending	\N
perf-test-32-ce519a16@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:09.486447+07	2025-08-22 16:55:09.486447+07	ce519a16-348d-4faa-b505-94feb981abc1	\N	["guest"]	pending	\N
perf-test-33-4bb6d4ad@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:09.486857+07	2025-08-22 16:55:09.486858+07	4bb6d4ad-988f-424d-bf54-ecb0ecb3cbcb	\N	["guest"]	pending	\N
perf-test-34-f5593624@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:09.487246+07	2025-08-22 16:55:09.487247+07	f5593624-5d02-4b1d-9a90-347af4ef2fee	\N	["guest"]	pending	\N
perf-test-35-926bb12a@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:09.487673+07	2025-08-22 16:55:09.487673+07	926bb12a-0ade-4d83-ae41-1d73ec29612c	\N	["guest"]	pending	\N
perf-test-36-64b92636@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:09.488138+07	2025-08-22 16:55:09.488138+07	64b92636-9249-468f-81ee-785aae919fa5	\N	["guest"]	pending	\N
perf-test-37-64ae5e42@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:09.488629+07	2025-08-22 16:55:09.488629+07	64ae5e42-5897-42d6-a8e3-93f1e7e17d2b	\N	["guest"]	pending	\N
perf-test-38-896a04d2@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:09.489322+07	2025-08-22 16:55:09.489322+07	896a04d2-1eb5-408c-8fc2-40000f0f1fdd	\N	["guest"]	pending	\N
perf-test-39-e0b1fb58@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:09.489979+07	2025-08-22 16:55:09.48998+07	e0b1fb58-0ceb-407d-8fc8-bd939e4fe100	\N	["guest"]	pending	\N
perf-test-40-d5840dd2@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:09.490623+07	2025-08-22 16:55:09.490623+07	d5840dd2-def0-45cb-b0e8-b741ec78db28	\N	["guest"]	pending	\N
perf-test-41-3ef4033c@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:09.491258+07	2025-08-22 16:55:09.491258+07	3ef4033c-db32-43b2-9bf0-e412bdae49e4	\N	["guest"]	pending	\N
perf-test-42-f5ff75f6@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:09.491863+07	2025-08-22 16:55:09.491863+07	f5ff75f6-8520-4cb7-9a02-ecffcf323372	\N	["guest"]	pending	\N
perf-test-43-69bef535@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:09.492515+07	2025-08-22 16:55:09.492515+07	69bef535-1886-4073-ad04-86b65c61f89b	\N	["guest"]	pending	\N
perf-test-44-c43e7c5e@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:09.493453+07	2025-08-22 16:55:09.493453+07	c43e7c5e-e3ae-4aee-a1bc-8402455aa6e6	\N	["guest"]	pending	\N
perf-test-45-ed61086c@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:09.493978+07	2025-08-22 16:55:09.493978+07	ed61086c-81e2-4a32-948c-f0d185b2bd5e	\N	["guest"]	pending	\N
perf-test-46-249d4ce2@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:09.494357+07	2025-08-22 16:55:09.494357+07	249d4ce2-9edf-45ac-a44d-9619617a1631	\N	["guest"]	pending	\N
perf-test-47-b045159a@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:09.494738+07	2025-08-22 16:55:09.494738+07	b045159a-02a4-4b03-8439-935f8440635e	\N	["guest"]	pending	\N
perf-test-48-bcb8d59e@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:09.495227+07	2025-08-22 16:55:09.495227+07	bcb8d59e-66bd-4341-93a9-c39a76891ad7	\N	["guest"]	pending	\N
perf-test-49-e57088ac@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:09.495928+07	2025-08-22 16:55:09.495928+07	e57088ac-0af9-45ad-84ae-72dcd00ad36b	\N	["guest"]	pending	\N
user-4-f1102c80@example.com	User 4	hashedpassword	\N	\N	t	2025-08-22 16:55:45.962269+07	2025-08-22 16:55:45.962269+07	f1102c80-035f-4e3a-b63c-70e647be7e64	\N	["guest"]	pending	\N
user-6-36806b6f@example.com	User 6	hashedpassword	\N	\N	t	2025-08-22 16:55:45.969122+07	2025-08-22 16:55:45.969122+07	36806b6f-ec41-4409-8d5b-8987a6f94257	\N	["guest"]	pending	\N
user-9-eed44d5b@example.com	User 9	hashedpassword	\N	\N	t	2025-08-22 16:55:45.971456+07	2025-08-22 16:55:45.971456+07	eed44d5b-caa0-4d4e-a2f7-6c930767649d	\N	["guest"]	pending	\N
user-10-d35e7027@example.com	User 10	hashedpassword	\N	\N	t	2025-08-22 16:55:45.97219+07	2025-08-22 16:55:45.97219+07	d35e7027-713e-44e4-87d1-7de3de263cc5	\N	["guest"]	pending	\N
user-15-40cf89cc@example.com	User 15	hashedpassword	\N	\N	t	2025-08-22 16:55:45.975063+07	2025-08-22 16:55:45.975063+07	40cf89cc-5e44-46ac-a2c7-3f4ef89e5397	\N	["guest"]	pending	\N
user-16-10d4bb79@example.com	User 16	hashedpassword	\N	\N	t	2025-08-22 16:55:45.975522+07	2025-08-22 16:55:45.975522+07	10d4bb79-593a-4d23-9aac-ae6a83e8798d	\N	["guest"]	pending	\N
user-18-ef846591@example.com	User 18	hashedpassword	\N	\N	t	2025-08-22 16:55:45.976312+07	2025-08-22 16:55:45.976312+07	ef846591-acfb-49cf-84b9-32748ceecef7	\N	["guest"]	pending	\N
user-23-27d0288e@example.com	User 23	hashedpassword	\N	\N	t	2025-08-22 16:55:45.978182+07	2025-08-22 16:55:45.978182+07	27d0288e-9b55-4fbf-80bf-8743c0e3ceef	\N	["guest"]	pending	\N
user-27-7fa77192@example.com	User 27	hashedpassword	\N	\N	t	2025-08-22 16:55:45.981032+07	2025-08-22 16:55:45.981032+07	7fa77192-9bfd-4b2c-9daf-730443651c83	\N	["guest"]	pending	\N
user-32-ecbf4a91@example.com	User 32	hashedpassword	\N	\N	t	2025-08-22 16:55:45.985513+07	2025-08-22 16:55:45.985513+07	ecbf4a91-b459-40c6-befa-f370f9e2803d	\N	["guest"]	pending	\N
user-36-89872063@example.com	User 36	hashedpassword	\N	\N	t	2025-08-22 16:55:45.987755+07	2025-08-22 16:55:45.987755+07	89872063-e311-4501-804f-a627ad4ed72f	\N	["guest"]	pending	\N
user-40-2749036f@example.com	User 40	hashedpassword	\N	\N	t	2025-08-22 16:55:45.989674+07	2025-08-22 16:55:45.989674+07	2749036f-977f-4f8b-9a75-eae815a2119d	\N	["guest"]	pending	\N
user-41-e7f7bab8@example.com	User 41	hashedpassword	\N	\N	t	2025-08-22 16:55:45.990068+07	2025-08-22 16:55:45.990068+07	e7f7bab8-f39e-47b4-9739-268a3bca9c9d	\N	["guest"]	pending	\N
user-42-8e8d41f2@example.com	User 42	hashedpassword	\N	\N	t	2025-08-22 16:55:45.990487+07	2025-08-22 16:55:45.990487+07	8e8d41f2-c270-43c9-987a-a3f31398bcd5	\N	["guest"]	pending	\N
user-48-ec3cc7cb@example.com	User 48	hashedpassword	\N	\N	t	2025-08-22 16:55:45.99382+07	2025-08-22 16:55:45.99382+07	ec3cc7cb-fa8e-4125-b49a-50c057c0485d	\N	["guest"]	pending	\N
user-49-ec9a96b2@example.com	User 49	hashedpassword	\N	\N	t	2025-08-22 16:55:45.99421+07	2025-08-22 16:55:45.99421+07	ec9a96b2-8022-4945-a685-0505b2cb62ae	\N	["guest"]	pending	\N
user-50-e859584e@example.com	User 50	hashedpassword	\N	\N	t	2025-08-22 16:55:45.994584+07	2025-08-22 16:55:45.994584+07	e859584e-c24c-43ff-888e-7339f3fb1259	\N	["guest"]	pending	\N
user-54-35d7b4ae@example.com	User 54	hashedpassword	\N	\N	t	2025-08-22 16:55:45.99626+07	2025-08-22 16:55:45.99626+07	35d7b4ae-4b4f-42ba-b4b2-7413a31ce0ba	\N	["guest"]	pending	\N
user-59-ad2145be@example.com	User 59	hashedpassword	\N	\N	t	2025-08-22 16:55:46.000254+07	2025-08-22 16:55:46.000254+07	ad2145be-9d44-47f7-9ffa-e3ccefb69273	\N	["guest"]	pending	\N
user-61-65f57e73@example.com	User 61	hashedpassword	\N	\N	t	2025-08-22 16:55:46.00194+07	2025-08-22 16:55:46.001941+07	65f57e73-bdb1-4328-8127-0fb3abe3e0c0	\N	["guest"]	pending	\N
user-62-98bfdace@example.com	User 62	hashedpassword	\N	\N	t	2025-08-22 16:55:46.002451+07	2025-08-22 16:55:46.002451+07	98bfdace-990b-4829-a3e6-ceb4c6bfa89c	\N	["guest"]	pending	\N
user-67-58874b7a@example.com	User 67	hashedpassword	\N	\N	t	2025-08-22 16:55:46.005768+07	2025-08-22 16:55:46.005768+07	58874b7a-3663-44bd-9f9f-dfb2c4b6a2b9	\N	["guest"]	pending	\N
user-68-c5bba4b3@example.com	User 68	hashedpassword	\N	\N	t	2025-08-22 16:55:46.006358+07	2025-08-22 16:55:46.006358+07	c5bba4b3-525e-42a8-ba32-05c35178466a	\N	["guest"]	pending	\N
user-72-685239d0@example.com	User 72	hashedpassword	\N	\N	t	2025-08-22 16:55:46.008179+07	2025-08-22 16:55:46.008179+07	685239d0-e146-49f2-8a26-38e12c8920ff	\N	["guest"]	pending	\N
user-74-a22ed510@example.com	User 74	hashedpassword	\N	\N	t	2025-08-22 16:55:46.00899+07	2025-08-22 16:55:46.00899+07	a22ed510-60b4-4092-9616-60eb877f84f0	\N	["guest"]	pending	\N
user-80-7d94fa31@example.com	User 80	hashedpassword	\N	\N	t	2025-08-22 16:55:46.011712+07	2025-08-22 16:55:46.011712+07	7d94fa31-1656-45ca-ad6a-238f49f2f6d9	\N	["guest"]	pending	\N
user-84-75d327ea@example.com	User 84	hashedpassword	\N	\N	t	2025-08-22 16:55:46.014172+07	2025-08-22 16:55:46.014172+07	75d327ea-336b-4451-aaa2-80f0d9cbfe06	\N	["guest"]	pending	\N
user-85-f9e75a58@example.com	User 85	hashedpassword	\N	\N	t	2025-08-22 16:55:46.015811+07	2025-08-22 16:55:46.015812+07	f9e75a58-24ac-4950-8816-511fbd57c6fd	\N	["guest"]	pending	\N
user-94-920b7f23@example.com	User 94	hashedpassword	\N	\N	t	2025-08-22 16:55:46.022593+07	2025-08-22 16:55:46.022593+07	920b7f23-dbf5-4106-b082-231470b6ffca	\N	["guest"]	pending	\N
concurrent-user-4-29f7b758@example.com	Concurrent User 4	password	\N	\N	t	2025-08-22 16:55:46.283214+07	2025-08-22 16:55:46.283214+07	29f7b758-9bd3-45d8-b698-2fcb0fd4d147	\N	["guest"]	pending	\N
concurrent-user-0-3ce8b848@example.com	Concurrent User 0	password	\N	\N	t	2025-08-22 16:55:46.283221+07	2025-08-22 16:55:46.283221+07	3ce8b848-da25-4e69-a8fd-74b83ac35e97	\N	["guest"]	pending	\N
perf-test-0-96058d76@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:46.422872+07	2025-08-22 16:55:46.422873+07	96058d76-3ee9-49b1-8936-de730119f4a8	\N	["guest"]	pending	\N
perf-test-1-35102c9e@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:46.424416+07	2025-08-22 16:55:46.424416+07	35102c9e-fb0e-456b-893f-21612242cd76	\N	["guest"]	pending	\N
perf-test-2-95b54176@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:46.425018+07	2025-08-22 16:55:46.425019+07	95b54176-c834-43c9-9403-754f17c85750	\N	["guest"]	pending	\N
perf-test-3-07949af7@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:46.425449+07	2025-08-22 16:55:46.425449+07	07949af7-fbae-4f9c-92b8-a730ea819a36	\N	["guest"]	pending	\N
perf-test-4-ccbf56af@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:46.425889+07	2025-08-22 16:55:46.425889+07	ccbf56af-7d94-4ac6-8a3f-7307198b6e13	\N	["guest"]	pending	\N
perf-test-5-581fc7eb@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:46.426289+07	2025-08-22 16:55:46.426289+07	581fc7eb-ac08-4eac-b648-2fddda239a49	\N	["guest"]	pending	\N
perf-test-6-c898db39@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:46.426657+07	2025-08-22 16:55:46.426657+07	c898db39-b069-40b5-bf12-506f101cce33	\N	["guest"]	pending	\N
perf-test-7-fdc4800e@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:46.427042+07	2025-08-22 16:55:46.427042+07	fdc4800e-9126-41fb-8378-8ae6f8f545c3	\N	["guest"]	pending	\N
perf-test-8-f186cfcf@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:46.427408+07	2025-08-22 16:55:46.427408+07	f186cfcf-e03b-486c-8d5f-3e617eb7dee2	\N	["guest"]	pending	\N
perf-test-9-2e820179@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:46.427768+07	2025-08-22 16:55:46.427768+07	2e820179-e094-4b7b-bdfb-761bba1f13f6	\N	["guest"]	pending	\N
perf-test-10-5e79a068@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:46.428346+07	2025-08-22 16:55:46.428346+07	5e79a068-6fb7-4d7c-b3d4-b4f329372c4d	\N	["guest"]	pending	\N
perf-test-11-1c725afb@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:46.428961+07	2025-08-22 16:55:46.428961+07	1c725afb-e011-4ad1-b3c7-930071f71900	\N	["guest"]	pending	\N
perf-test-12-62d8eb6e@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:46.429451+07	2025-08-22 16:55:46.429451+07	62d8eb6e-b5f3-4ca9-a266-13ad7d133fe4	\N	["guest"]	pending	\N
perf-test-13-6ef9c9e8@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:46.430139+07	2025-08-22 16:55:46.43014+07	6ef9c9e8-e705-439a-82f8-ad10dc5548d9	\N	["guest"]	pending	\N
perf-test-14-e2c50cde@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:46.430962+07	2025-08-22 16:55:46.430962+07	e2c50cde-58a2-4fba-aab0-99acd80679b0	\N	["guest"]	pending	\N
perf-test-15-6768ae0f@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:46.43164+07	2025-08-22 16:55:46.431641+07	6768ae0f-5911-4c98-b146-6747fb3ee0d3	\N	["guest"]	pending	\N
perf-test-16-b7378041@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:46.432269+07	2025-08-22 16:55:46.432269+07	b7378041-07a4-4380-a163-92b0e659bbea	\N	["guest"]	pending	\N
perf-test-17-65b74ca8@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:46.43286+07	2025-08-22 16:55:46.43286+07	65b74ca8-bec2-48a2-a5d5-bd695a41a6c5	\N	["guest"]	pending	\N
perf-test-18-e8cdab22@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:46.433439+07	2025-08-22 16:55:46.433439+07	e8cdab22-812d-4226-9097-ba96dd397606	\N	["guest"]	pending	\N
perf-test-19-64a92073@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:46.434246+07	2025-08-22 16:55:46.434246+07	64a92073-be86-452a-a035-9c99c65647c2	\N	["guest"]	pending	\N
perf-test-20-55dc5edc@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:46.434869+07	2025-08-22 16:55:46.434869+07	55dc5edc-dcbd-47d6-85f2-34f1a5240772	\N	["guest"]	pending	\N
perf-test-21-9226c95a@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:46.435312+07	2025-08-22 16:55:46.435312+07	9226c95a-4552-4ee8-a40c-6620140bd837	\N	["guest"]	pending	\N
perf-test-22-b33858d0@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:46.435778+07	2025-08-22 16:55:46.435778+07	b33858d0-d136-415f-9a87-f75bb00617e0	\N	["guest"]	pending	\N
perf-test-23-223a6c78@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:46.436387+07	2025-08-22 16:55:46.436387+07	223a6c78-bde1-4876-853a-c2d2d03ca10b	\N	["guest"]	pending	\N
perf-test-24-808693f2@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:46.436875+07	2025-08-22 16:55:46.436876+07	808693f2-8422-4f70-8d41-0918f16d775c	\N	["guest"]	pending	\N
perf-test-25-87f136b4@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:46.437341+07	2025-08-22 16:55:46.437341+07	87f136b4-3d0d-4fe9-a4cb-fe108bded7e0	\N	["guest"]	pending	\N
perf-test-26-3bd62c8b@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:46.437789+07	2025-08-22 16:55:46.437789+07	3bd62c8b-dbfc-41df-b8ce-c87acc4f5453	\N	["guest"]	pending	\N
perf-test-27-77d45da5@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:46.438231+07	2025-08-22 16:55:46.438231+07	77d45da5-c8cc-49a9-b628-b8ff5b9c28d4	\N	["guest"]	pending	\N
perf-test-28-f189c5a4@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:46.438664+07	2025-08-22 16:55:46.438664+07	f189c5a4-c860-4daa-905e-563281e59880	\N	["guest"]	pending	\N
perf-test-29-2d68b597@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:46.439049+07	2025-08-22 16:55:46.439049+07	2d68b597-51c2-4aad-9cd6-2f0412424b0b	\N	["guest"]	pending	\N
perf-test-30-352c7c6f@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:46.439443+07	2025-08-22 16:55:46.439443+07	352c7c6f-e559-440d-b4d3-7d5c1fd0daae	\N	["guest"]	pending	\N
perf-test-31-f16662fb@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:46.43984+07	2025-08-22 16:55:46.439841+07	f16662fb-de2e-4d19-a49a-fa93915c677f	\N	["guest"]	pending	\N
perf-test-32-b85dd8e6@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:46.440211+07	2025-08-22 16:55:46.440211+07	b85dd8e6-0b8f-48a7-9ed3-fbe5786d8b41	\N	["guest"]	pending	\N
perf-test-33-88c1809a@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:46.440557+07	2025-08-22 16:55:46.440557+07	88c1809a-1cbc-4861-bea9-93aef6e3b2a2	\N	["guest"]	pending	\N
perf-test-34-c34858ae@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:46.440889+07	2025-08-22 16:55:46.440889+07	c34858ae-13a3-4f58-9334-df3d0c59a58a	\N	["guest"]	pending	\N
perf-test-35-fc4ab47b@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:46.441238+07	2025-08-22 16:55:46.441239+07	fc4ab47b-87be-476f-a4c6-8c9447222be3	\N	["guest"]	pending	\N
perf-test-36-8e3d18fd@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:46.441589+07	2025-08-22 16:55:46.441589+07	8e3d18fd-6493-4c4b-8872-fac349e630c6	\N	["guest"]	pending	\N
perf-test-37-5e97c899@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:46.441931+07	2025-08-22 16:55:46.441931+07	5e97c899-5b34-491c-a522-41a7180a978e	\N	["guest"]	pending	\N
perf-test-38-3b8e2e6e@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:46.442252+07	2025-08-22 16:55:46.442252+07	3b8e2e6e-2373-4b34-9fa2-8b2537a1dbc0	\N	["guest"]	pending	\N
perf-test-39-9939d641@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:46.442576+07	2025-08-22 16:55:46.442576+07	9939d641-da3f-4c7d-93f7-f423eea54e51	\N	["guest"]	pending	\N
perf-test-40-2d8beb18@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:46.44293+07	2025-08-22 16:55:46.442931+07	2d8beb18-bc2c-4064-8d7d-27cae93b0969	\N	["guest"]	pending	\N
perf-test-41-1f68dd8c@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:46.443269+07	2025-08-22 16:55:46.443269+07	1f68dd8c-e5ef-450d-a0e4-fe8caa6fab48	\N	["guest"]	pending	\N
perf-test-42-49db04d1@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:46.443584+07	2025-08-22 16:55:46.443584+07	49db04d1-81c8-47b8-a955-b57b2bccacd7	\N	["guest"]	pending	\N
perf-test-43-b8958b85@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:46.443914+07	2025-08-22 16:55:46.443914+07	b8958b85-7615-4599-b416-962602d9aa11	\N	["guest"]	pending	\N
perf-test-44-f2839efd@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:46.444271+07	2025-08-22 16:55:46.444271+07	f2839efd-70c5-4375-a1bc-b2c842e9d55e	\N	["guest"]	pending	\N
perf-test-45-46c27f79@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:46.444657+07	2025-08-22 16:55:46.444657+07	46c27f79-641e-4a6a-8ead-2db498355fcd	\N	["guest"]	pending	\N
perf-test-46-2a17d6ff@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:46.445007+07	2025-08-22 16:55:46.445007+07	2a17d6ff-c7f4-42b0-be84-c34abc169490	\N	["guest"]	pending	\N
perf-test-47-392912fc@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:46.445401+07	2025-08-22 16:55:46.445401+07	392912fc-55de-443b-b256-4bb8ec96865f	\N	["guest"]	pending	\N
perf-test-48-9d06bc29@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:46.445978+07	2025-08-22 16:55:46.445979+07	9d06bc29-963f-4365-8b3b-0d57d5214fef	\N	["guest"]	pending	\N
perf-test-49-20b322fb@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:46.44648+07	2025-08-22 16:55:46.44648+07	20b322fb-e1bf-48be-a859-3bdd8d162c42	\N	["guest"]	pending	\N
user-8-795b8cdf@example.com	User 8	hashedpassword	\N	\N	t	2025-08-22 16:56:17.283641+07	2025-08-22 16:56:17.283641+07	795b8cdf-dc74-487b-82a8-d62d998e3d77	\N	["guest"]	pending	\N
user-14-bfb02230@example.com	User 14	hashedpassword	\N	\N	t	2025-08-22 16:56:17.291594+07	2025-08-22 16:56:17.291594+07	bfb02230-5004-4878-ba1b-6d631fc41a4b	\N	["guest"]	pending	\N
user-16-bf528a04@example.com	User 16	hashedpassword	\N	\N	t	2025-08-22 16:56:17.293122+07	2025-08-22 16:56:17.293123+07	bf528a04-f491-4e0b-a572-35541612ee37	\N	["guest"]	pending	\N
user-19-e7294cc0@example.com	User 19	hashedpassword	\N	\N	t	2025-08-22 16:56:17.295752+07	2025-08-22 16:56:17.295752+07	e7294cc0-c924-4d95-9c67-e2ca8e40a482	\N	["guest"]	pending	\N
user-22-0582e610@example.com	User 22	hashedpassword	\N	\N	t	2025-08-22 16:56:17.297513+07	2025-08-22 16:56:17.297513+07	0582e610-f88b-4e5f-9fe5-ebe5f43ee970	\N	["guest"]	pending	\N
user-23-1437a026@example.com	User 23	hashedpassword	\N	\N	t	2025-08-22 16:56:17.298075+07	2025-08-22 16:56:17.298075+07	1437a026-2139-49ee-bc1e-64d9712020a4	\N	["guest"]	pending	\N
user-26-d3bc6861@example.com	User 26	hashedpassword	\N	\N	t	2025-08-22 16:56:17.299886+07	2025-08-22 16:56:17.299886+07	d3bc6861-2fda-441e-a36b-9aadb45c6896	\N	["guest"]	pending	\N
user-29-96998323@example.com	User 29	hashedpassword	\N	\N	t	2025-08-22 16:56:17.301225+07	2025-08-22 16:56:17.301225+07	96998323-fcf1-473f-a6db-f29c05e8c4d2	\N	["guest"]	pending	\N
user-32-ff431810@example.com	User 32	hashedpassword	\N	\N	t	2025-08-22 16:56:17.303259+07	2025-08-22 16:56:17.303259+07	ff431810-cc72-4978-b411-2979337d4ccc	\N	["guest"]	pending	\N
user-33-612ea634@example.com	User 33	hashedpassword	\N	\N	t	2025-08-22 16:56:17.304209+07	2025-08-22 16:56:17.304209+07	612ea634-d857-414d-8f97-344fad75539e	\N	["guest"]	pending	\N
user-35-46257489@example.com	User 35	hashedpassword	\N	\N	t	2025-08-22 16:56:17.30766+07	2025-08-22 16:56:17.30766+07	46257489-fa9e-4987-91f2-1e86f1d09a58	\N	["guest"]	pending	\N
user-36-eca50c34@example.com	User 36	hashedpassword	\N	\N	t	2025-08-22 16:56:17.309062+07	2025-08-22 16:56:17.309062+07	eca50c34-7c86-4ba1-9336-46da7ba501fb	\N	["guest"]	pending	\N
user-42-373ca0a8@example.com	User 42	hashedpassword	\N	\N	t	2025-08-22 16:56:17.313163+07	2025-08-22 16:56:17.313163+07	373ca0a8-8da7-4406-92b5-80c67b873517	\N	["guest"]	pending	\N
user-43-ac920321@example.com	User 43	hashedpassword	\N	\N	t	2025-08-22 16:56:17.31373+07	2025-08-22 16:56:17.31373+07	ac920321-defb-4519-bbfc-d2ccb7172fd3	\N	["guest"]	pending	\N
user-52-4e4dd91e@example.com	User 52	hashedpassword	\N	\N	t	2025-08-22 16:56:17.318711+07	2025-08-22 16:56:17.318712+07	4e4dd91e-17f4-4197-bfba-9c529d2978e8	\N	["guest"]	pending	\N
user-55-aab0735a@example.com	User 55	hashedpassword	\N	\N	t	2025-08-22 16:56:17.32014+07	2025-08-22 16:56:17.320141+07	aab0735a-72ab-4850-ab77-996006c9a6e2	\N	["guest"]	pending	\N
user-57-dd67f5ef@example.com	User 57	hashedpassword	\N	\N	t	2025-08-22 16:56:17.322556+07	2025-08-22 16:56:17.322556+07	dd67f5ef-50a3-41cf-888d-3c7b3932362c	\N	["guest"]	pending	\N
user-58-34623bb5@example.com	User 58	hashedpassword	\N	\N	t	2025-08-22 16:56:17.323557+07	2025-08-22 16:56:17.323557+07	34623bb5-ff0a-4171-bfa2-ba1acac04505	\N	["guest"]	pending	\N
user-59-1e07998e@example.com	User 59	hashedpassword	\N	\N	t	2025-08-22 16:56:17.324422+07	2025-08-22 16:56:17.324422+07	1e07998e-1cae-4541-9dff-5ccfa2318be7	\N	["guest"]	pending	\N
user-65-fe31e745@example.com	User 65	hashedpassword	\N	\N	t	2025-08-22 16:56:17.328443+07	2025-08-22 16:56:17.328443+07	fe31e745-e43f-4ee8-90ad-0316f884237d	\N	["guest"]	pending	\N
user-68-234963eb@example.com	User 68	hashedpassword	\N	\N	t	2025-08-22 16:56:17.329706+07	2025-08-22 16:56:17.329706+07	234963eb-3dc2-4d98-b335-3c47dd41d67f	\N	["guest"]	pending	\N
user-69-a97dd50f@example.com	User 69	hashedpassword	\N	\N	t	2025-08-22 16:56:17.330075+07	2025-08-22 16:56:17.330075+07	a97dd50f-c21d-41ff-87d3-158cbda5fb4d	\N	["guest"]	pending	\N
user-70-5b24b0fd@example.com	User 70	hashedpassword	\N	\N	t	2025-08-22 16:56:17.330435+07	2025-08-22 16:56:17.330435+07	5b24b0fd-0908-4c3a-b685-0842263ee3db	\N	["guest"]	pending	\N
user-78-8179c270@example.com	User 78	hashedpassword	\N	\N	t	2025-08-22 16:56:17.333455+07	2025-08-22 16:56:17.333455+07	8179c270-fa39-4e79-9a54-0d662f8b0871	\N	["guest"]	pending	\N
user-81-6d00bce9@example.com	User 81	hashedpassword	\N	\N	t	2025-08-22 16:56:17.334558+07	2025-08-22 16:56:17.334558+07	6d00bce9-4f68-4673-8f88-1a060c36c9ac	\N	["guest"]	pending	\N
user-89-35af5558@example.com	User 89	hashedpassword	\N	\N	t	2025-08-22 16:56:17.342428+07	2025-08-22 16:56:17.342428+07	35af5558-850a-4d68-a594-db87366c4e90	\N	["guest"]	pending	\N
user-90-46114fcc@example.com	User 90	hashedpassword	\N	\N	t	2025-08-22 16:56:17.343152+07	2025-08-22 16:56:17.343152+07	46114fcc-77e4-4c91-afc4-673be98c295f	\N	["guest"]	pending	\N
user-96-96454df1@example.com	User 96	hashedpassword	\N	\N	t	2025-08-22 16:56:17.347228+07	2025-08-22 16:56:17.347228+07	96454df1-7de5-48ab-a4d5-fff9d513a607	\N	["guest"]	pending	\N
concurrent-user-0-ccd5b82f@example.com	Concurrent User 0	password	\N	\N	t	2025-08-22 16:56:17.628904+07	2025-08-22 16:56:17.628904+07	ccd5b82f-e622-4e2e-b593-7b578762752d	\N	["guest"]	pending	\N
concurrent-user-4-e2e1c579@example.com	Concurrent User 4	password	\N	\N	t	2025-08-22 16:56:17.628723+07	2025-08-22 16:56:17.628723+07	e2e1c579-4d4b-4fa4-973f-efe2324aa0d7	\N	["guest"]	pending	\N
perf-test-0-a1c85b7d@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:56:17.785165+07	2025-08-22 16:56:17.785165+07	a1c85b7d-e9e9-4dd4-b1a8-582d2d6fcd48	\N	["guest"]	pending	\N
perf-test-1-6cdafb55@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:56:17.7867+07	2025-08-22 16:56:17.7867+07	6cdafb55-1a1a-42c0-9e9a-27d88fc9ebde	\N	["guest"]	pending	\N
perf-test-2-addae1e6@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:56:17.78824+07	2025-08-22 16:56:17.78824+07	addae1e6-4575-4d6a-9f3f-512f9bb83730	\N	["guest"]	pending	\N
perf-test-3-5fee36e2@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:56:17.790781+07	2025-08-22 16:56:17.790781+07	5fee36e2-ab82-4980-9b28-86f979dceb8b	\N	["guest"]	pending	\N
perf-test-4-65d0b511@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:56:17.792168+07	2025-08-22 16:56:17.792168+07	65d0b511-16be-46aa-9a65-21b26f773e4b	\N	["guest"]	pending	\N
perf-test-5-022698b7@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:56:17.792646+07	2025-08-22 16:56:17.792646+07	022698b7-c71e-490a-b130-e4faf5f78b45	\N	["guest"]	pending	\N
perf-test-6-fccc08e1@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:56:17.793521+07	2025-08-22 16:56:17.793522+07	fccc08e1-fbdb-4785-be2b-a6ee1e148e04	\N	["guest"]	pending	\N
perf-test-7-404dab5a@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:56:17.794246+07	2025-08-22 16:56:17.794246+07	404dab5a-9d57-4076-98e6-b0c2a350a8fc	\N	["guest"]	pending	\N
perf-test-8-a4c351a0@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:56:17.794997+07	2025-08-22 16:56:17.794997+07	a4c351a0-b6bd-4bb6-bd69-aa6336fba456	\N	["guest"]	pending	\N
perf-test-9-4124990a@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:56:17.795698+07	2025-08-22 16:56:17.795698+07	4124990a-4100-41d1-8208-14edc0286502	\N	["guest"]	pending	\N
perf-test-10-237e7524@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:56:17.79633+07	2025-08-22 16:56:17.79633+07	237e7524-c545-4960-a526-b733a53e0ba3	\N	["guest"]	pending	\N
perf-test-11-8de7618a@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:56:17.796976+07	2025-08-22 16:56:17.796976+07	8de7618a-bacf-44ed-ae59-db6539a6fb78	\N	["guest"]	pending	\N
perf-test-12-5d4e012d@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:56:17.797531+07	2025-08-22 16:56:17.797531+07	5d4e012d-f029-4563-a551-b46d2b7546ea	\N	["guest"]	pending	\N
perf-test-13-be43333a@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:56:17.798093+07	2025-08-22 16:56:17.798094+07	be43333a-5d2d-4a6a-be6d-91e539861f87	\N	["guest"]	pending	\N
perf-test-14-4c7641a1@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:56:17.798649+07	2025-08-22 16:56:17.798649+07	4c7641a1-2bb5-40d9-94da-86d7c8c250ad	\N	["guest"]	pending	\N
perf-test-15-5ca16e16@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:56:17.799126+07	2025-08-22 16:56:17.799126+07	5ca16e16-dda6-4770-a4db-06adf0df638b	\N	["guest"]	pending	\N
perf-test-16-45fee027@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:56:17.799602+07	2025-08-22 16:56:17.799602+07	45fee027-6470-43e2-8935-3c2e68c2dae6	\N	["guest"]	pending	\N
perf-test-17-026de789@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:56:17.800073+07	2025-08-22 16:56:17.800073+07	026de789-0801-4502-9617-cddcafbdce2d	\N	["guest"]	pending	\N
perf-test-18-56674abb@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:56:17.800546+07	2025-08-22 16:56:17.800546+07	56674abb-bd2a-4c80-bcd5-13bf069415a8	\N	["guest"]	pending	\N
perf-test-19-3574e5b3@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:56:17.801021+07	2025-08-22 16:56:17.801021+07	3574e5b3-963e-494f-ad60-1517e7bd2630	\N	["guest"]	pending	\N
perf-test-20-e9d6f512@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:56:17.801666+07	2025-08-22 16:56:17.801667+07	e9d6f512-425b-484d-b3b4-0fd9a9715430	\N	["guest"]	pending	\N
perf-test-21-ece44329@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:56:17.802223+07	2025-08-22 16:56:17.802223+07	ece44329-b8e9-4ee6-b576-ca84b6ba61a7	\N	["guest"]	pending	\N
perf-test-22-72991369@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:56:17.802783+07	2025-08-22 16:56:17.802783+07	72991369-a233-4bf4-81cc-91daddad751b	\N	["guest"]	pending	\N
perf-test-23-06647970@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:56:17.803358+07	2025-08-22 16:56:17.803358+07	06647970-e9ce-4c91-9e48-140dc457c157	\N	["guest"]	pending	\N
perf-test-24-c8b4a68a@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:56:17.804137+07	2025-08-22 16:56:17.804138+07	c8b4a68a-fc34-439d-b24f-9dab9d116acd	\N	["guest"]	pending	\N
perf-test-25-a26054ac@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:56:17.805577+07	2025-08-22 16:56:17.805577+07	a26054ac-cdee-4a94-b107-c5c87d256d22	\N	["guest"]	pending	\N
perf-test-26-7e4d1bf1@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:56:17.806866+07	2025-08-22 16:56:17.806866+07	7e4d1bf1-8785-42bb-bd35-e3a3e015d6fa	\N	["guest"]	pending	\N
perf-test-27-217927e0@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:56:17.808006+07	2025-08-22 16:56:17.808007+07	217927e0-86f2-4b4f-a093-0db21de4de67	\N	["guest"]	pending	\N
perf-test-28-4b1f312f@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:56:17.808694+07	2025-08-22 16:56:17.808694+07	4b1f312f-a3db-44ed-b7c0-61c7e6a27f19	\N	["guest"]	pending	\N
perf-test-29-9752c1e5@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:56:17.809255+07	2025-08-22 16:56:17.809255+07	9752c1e5-7d24-4f6d-bac4-e0a719128fa5	\N	["guest"]	pending	\N
perf-test-30-49674aaf@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:56:17.810035+07	2025-08-22 16:56:17.810035+07	49674aaf-7a0a-4765-8e5d-9018eca712e1	\N	["guest"]	pending	\N
perf-test-31-2d8232a6@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:56:17.810765+07	2025-08-22 16:56:17.810765+07	2d8232a6-7e9d-4133-97b7-ec17713ea12b	\N	["guest"]	pending	\N
perf-test-32-8a880ba3@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:56:17.811489+07	2025-08-22 16:56:17.811489+07	8a880ba3-0966-49cb-9c8b-017066162926	\N	["guest"]	pending	\N
perf-test-33-d536486f@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:56:17.812344+07	2025-08-22 16:56:17.812344+07	d536486f-9e92-422a-9b73-4ff60fe2a2b1	\N	["guest"]	pending	\N
perf-test-34-072d49f2@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:56:17.812963+07	2025-08-22 16:56:17.812963+07	072d49f2-dbbc-4fcb-947e-7b30272abb90	\N	["guest"]	pending	\N
perf-test-35-0c8f8952@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:56:17.813568+07	2025-08-22 16:56:17.813568+07	0c8f8952-e65f-4ed6-bbd3-6d3c4dcb44c0	\N	["guest"]	pending	\N
perf-test-36-500efac9@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:56:17.814135+07	2025-08-22 16:56:17.814135+07	500efac9-912f-483b-a093-80f5c08fcaed	\N	["guest"]	pending	\N
perf-test-37-01e71d7f@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:56:17.814683+07	2025-08-22 16:56:17.814683+07	01e71d7f-9813-490b-95c8-e54eca208fd6	\N	["guest"]	pending	\N
perf-test-38-dca8d310@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:56:17.815189+07	2025-08-22 16:56:17.815189+07	dca8d310-199d-49e9-97db-2650466c598b	\N	["guest"]	pending	\N
perf-test-39-64fa6af3@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:56:17.815633+07	2025-08-22 16:56:17.815633+07	64fa6af3-d614-49a7-b7c4-446aaf42fd30	\N	["guest"]	pending	\N
perf-test-40-d5338eef@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:56:17.816048+07	2025-08-22 16:56:17.816048+07	d5338eef-c80b-4edc-b213-16ff9335c834	\N	["guest"]	pending	\N
perf-test-41-48880d65@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:56:17.816461+07	2025-08-22 16:56:17.816461+07	48880d65-286d-4bd7-afee-62caa56f5e61	\N	["guest"]	pending	\N
perf-test-42-7f6fb738@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:56:17.816878+07	2025-08-22 16:56:17.816878+07	7f6fb738-8543-482b-92ba-16e5c837e96c	\N	["guest"]	pending	\N
perf-test-43-15b4c274@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:56:17.817236+07	2025-08-22 16:56:17.817236+07	15b4c274-2e79-497a-a169-8755a6544d9b	\N	["guest"]	pending	\N
perf-test-44-e1d78bc1@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:56:17.817584+07	2025-08-22 16:56:17.817584+07	e1d78bc1-d7e9-4cff-8e1a-99b0d06f33a8	\N	["guest"]	pending	\N
perf-test-45-dac63897@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:56:17.817941+07	2025-08-22 16:56:17.817941+07	dac63897-197e-4d05-937d-1b19a9f91e39	\N	["guest"]	pending	\N
perf-test-46-2ac4a83d@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:56:17.818338+07	2025-08-22 16:56:17.818338+07	2ac4a83d-3423-41a2-8dd2-ddf89586f33d	\N	["guest"]	pending	\N
perf-test-47-2c04bff9@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:56:17.818715+07	2025-08-22 16:56:17.818715+07	2c04bff9-09c7-4d8b-8ae3-48b34894207a	\N	["guest"]	pending	\N
perf-test-48-13beaed4@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:56:17.819153+07	2025-08-22 16:56:17.819153+07	13beaed4-d926-4166-abe1-be2a075f43f3	\N	["guest"]	pending	\N
perf-test-49-5d1c5095@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:56:17.819886+07	2025-08-22 16:56:17.819886+07	5d1c5095-3b0c-418c-8e47-b347d5dfac1e	\N	["guest"]	pending	\N
user-0-848d406d@example.com	User 0	hashedpassword	\N	\N	t	2025-08-22 17:35:45.188845+07	2025-08-22 17:35:45.188845+07	848d406d-7838-4f82-b647-c457d05a1730	\N	["guest"]	pending	\N
user-1-96a36dd7@example.com	User 1	hashedpassword	\N	\N	t	2025-08-22 17:35:45.194045+07	2025-08-22 17:35:45.194045+07	96a36dd7-3a9b-44ef-b3ac-084e487eccec	\N	["guest"]	pending	\N
user-5-0c020dca@example.com	User 5	hashedpassword	\N	\N	t	2025-08-22 17:35:45.202224+07	2025-08-22 17:35:45.202224+07	0c020dca-ae3b-4fdc-ac33-3d79ba00ea48	\N	["guest"]	pending	\N
user-6-6ee9e8b0@example.com	User 6	hashedpassword	\N	\N	t	2025-08-22 17:35:45.20264+07	2025-08-22 17:35:45.20264+07	6ee9e8b0-f84a-4b61-be5b-4a654eb9d664	\N	["guest"]	pending	\N
user-9-57899f21@example.com	User 9	hashedpassword	\N	\N	t	2025-08-22 17:35:45.206571+07	2025-08-22 17:35:45.206571+07	57899f21-bbea-4632-9dab-7070b68c63e0	\N	["guest"]	pending	\N
user-11-177a350d@example.com	User 11	hashedpassword	\N	\N	t	2025-08-22 17:35:45.207387+07	2025-08-22 17:35:45.207387+07	177a350d-70f6-4624-a822-bc89a67e721c	\N	["guest"]	pending	\N
user-14-99b5410d@example.com	User 14	hashedpassword	\N	\N	t	2025-08-22 17:35:45.208466+07	2025-08-22 17:35:45.208466+07	99b5410d-acd3-4adb-b530-21f1199be60d	\N	["guest"]	pending	\N
user-29-89a598cf@example.com	User 29	hashedpassword	\N	\N	t	2025-08-22 17:35:45.214635+07	2025-08-22 17:35:45.214635+07	89a598cf-eded-4cb0-a21b-bdf2995350bd	\N	["guest"]	pending	\N
user-33-b797f3a5@example.com	User 33	hashedpassword	\N	\N	t	2025-08-22 17:35:45.21635+07	2025-08-22 17:35:45.21635+07	b797f3a5-bd27-49b6-b7e2-bf4787ef0b7b	\N	["guest"]	pending	\N
user-34-46fb23b2@example.com	User 34	hashedpassword	\N	\N	t	2025-08-22 17:35:45.216738+07	2025-08-22 17:35:45.216739+07	46fb23b2-d6da-4426-99c9-f98a53bfb4c1	\N	["guest"]	pending	\N
user-44-2d9b676f@example.com	User 44	hashedpassword	\N	\N	t	2025-08-22 17:35:45.220629+07	2025-08-22 17:35:45.22063+07	2d9b676f-c7ff-42d4-8992-f3a15f8c7e92	\N	["guest"]	pending	\N
user-49-f1a4f554@example.com	User 49	hashedpassword	\N	\N	t	2025-08-22 17:35:45.223047+07	2025-08-22 17:35:45.223047+07	f1a4f554-6433-40e7-a478-8c8b5715dc9b	\N	["guest"]	pending	\N
user-52-87338919@example.com	User 52	hashedpassword	\N	\N	t	2025-08-22 17:35:45.224303+07	2025-08-22 17:35:45.224303+07	87338919-cf10-4b41-bf23-8bf1ded308ae	\N	["guest"]	pending	\N
user-54-806b4204@example.com	User 54	hashedpassword	\N	\N	t	2025-08-22 17:35:45.225044+07	2025-08-22 17:35:45.225045+07	806b4204-d6a4-4c60-b3fa-83230cbe3f37	\N	["guest"]	pending	\N
user-62-61b52f7e@example.com	User 62	hashedpassword	\N	\N	t	2025-08-22 17:35:45.228153+07	2025-08-22 17:35:45.228153+07	61b52f7e-cb80-47a9-9a39-b747373abf1b	\N	["guest"]	pending	\N
user-67-090aeb94@example.com	User 67	hashedpassword	\N	\N	t	2025-08-22 17:35:45.230632+07	2025-08-22 17:35:45.230632+07	090aeb94-c0b6-402c-8bc6-332d83b1b192	\N	["guest"]	pending	\N
user-72-a596fe8e@example.com	User 72	hashedpassword	\N	\N	t	2025-08-22 17:35:45.232543+07	2025-08-22 17:35:45.232543+07	a596fe8e-04ab-42d8-aea0-b836c63102f9	\N	["guest"]	pending	\N
user-75-cff74f83@example.com	User 75	hashedpassword	\N	\N	t	2025-08-22 17:35:45.233619+07	2025-08-22 17:35:45.233619+07	cff74f83-8825-4c95-abe0-c7144de467e4	\N	["guest"]	pending	\N
user-76-aaa8e208@example.com	User 76	hashedpassword	\N	\N	t	2025-08-22 17:35:45.234009+07	2025-08-22 17:35:45.234009+07	aaa8e208-044c-481d-a044-0d71fc1facc0	\N	["guest"]	pending	\N
user-81-efba7301@example.com	User 81	hashedpassword	\N	\N	t	2025-08-22 17:35:45.235836+07	2025-08-22 17:35:45.235836+07	efba7301-6e2a-4628-b1af-e316d4bfe095	\N	["guest"]	pending	\N
user-88-9a8d83b5@example.com	User 88	hashedpassword	\N	\N	t	2025-08-22 17:35:45.239324+07	2025-08-22 17:35:45.239324+07	9a8d83b5-2605-4ee4-9c14-4775b383de12	\N	["guest"]	pending	\N
user-96-37c1eed8@example.com	User 96	hashedpassword	\N	\N	t	2025-08-22 17:35:45.242346+07	2025-08-22 17:35:45.242346+07	37c1eed8-8954-4bb6-97a7-e4b1287fd361	\N	["guest"]	pending	\N
concurrent-user-4-683a9950@example.com	Concurrent User 4	password	\N	\N	t	2025-08-22 17:35:45.432869+07	2025-08-22 17:35:45.43287+07	683a9950-7dd6-47f4-a330-451acd5ced8d	\N	["guest"]	pending	\N
concurrent-user-0-0b810d99@example.com	Concurrent User 0	password	\N	\N	t	2025-08-22 17:35:45.433011+07	2025-08-22 17:35:45.433011+07	0b810d99-fdbb-4a62-a13d-1b7b10eb2090	\N	["guest"]	pending	\N
perf-test-0-37cb4f09@example.com	Performance User 0	password	\N	\N	t	2025-08-22 17:35:45.550668+07	2025-08-22 17:35:45.550668+07	37cb4f09-3537-45b5-9cea-499b17e6e462	\N	["guest"]	pending	\N
perf-test-1-89a22d88@example.com	Performance User 1	password	\N	\N	t	2025-08-22 17:35:45.5523+07	2025-08-22 17:35:45.5523+07	89a22d88-16a2-4b85-8f63-a37d280c22c1	\N	["guest"]	pending	\N
perf-test-2-9d0fcc52@example.com	Performance User 2	password	\N	\N	t	2025-08-22 17:35:45.552815+07	2025-08-22 17:35:45.552815+07	9d0fcc52-1aa5-4106-86e3-7f220097e70a	\N	["guest"]	pending	\N
perf-test-3-3d6ac012@example.com	Performance User 3	password	\N	\N	t	2025-08-22 17:35:45.553231+07	2025-08-22 17:35:45.553232+07	3d6ac012-ad6d-499a-954e-33b2dba9be98	\N	["guest"]	pending	\N
perf-test-4-2b75d713@example.com	Performance User 4	password	\N	\N	t	2025-08-22 17:35:45.55372+07	2025-08-22 17:35:45.55372+07	2b75d713-6050-4354-9d40-d9dcdc4d52a2	\N	["guest"]	pending	\N
perf-test-5-bbdb9bd1@example.com	Performance User 5	password	\N	\N	t	2025-08-22 17:35:45.55419+07	2025-08-22 17:35:45.55419+07	bbdb9bd1-c441-4186-adb6-3929c77e91a6	\N	["guest"]	pending	\N
perf-test-6-a5b5d212@example.com	Performance User 6	password	\N	\N	t	2025-08-22 17:35:45.554589+07	2025-08-22 17:35:45.55459+07	a5b5d212-9776-4d62-a05a-f5c7b26a21e6	\N	["guest"]	pending	\N
perf-test-7-15218918@example.com	Performance User 7	password	\N	\N	t	2025-08-22 17:35:45.555045+07	2025-08-22 17:35:45.555045+07	15218918-6427-47d7-9df7-15118ad13d1b	\N	["guest"]	pending	\N
perf-test-8-77623689@example.com	Performance User 8	password	\N	\N	t	2025-08-22 17:35:45.55552+07	2025-08-22 17:35:45.55552+07	77623689-3d0a-47f3-85db-4d9ce7e7b22e	\N	["guest"]	pending	\N
perf-test-9-0ba6859f@example.com	Performance User 9	password	\N	\N	t	2025-08-22 17:35:45.556138+07	2025-08-22 17:35:45.556138+07	0ba6859f-7baf-487c-8a25-19ab475dfdf7	\N	["guest"]	pending	\N
perf-test-10-3c16bc52@example.com	Performance User 10	password	\N	\N	t	2025-08-22 17:35:45.557069+07	2025-08-22 17:35:45.55707+07	3c16bc52-cd4b-4580-a4b2-01f6a1bf5c3a	\N	["guest"]	pending	\N
perf-test-11-fa3bac29@example.com	Performance User 11	password	\N	\N	t	2025-08-22 17:35:45.557509+07	2025-08-22 17:35:45.557509+07	fa3bac29-e70f-471e-863f-92bb5efb2919	\N	["guest"]	pending	\N
perf-test-12-b945654c@example.com	Performance User 12	password	\N	\N	t	2025-08-22 17:35:45.557914+07	2025-08-22 17:35:45.557914+07	b945654c-21bd-42b7-bccf-5831d6b0e8c1	\N	["guest"]	pending	\N
perf-test-13-ec6df8cf@example.com	Performance User 13	password	\N	\N	t	2025-08-22 17:35:45.558401+07	2025-08-22 17:35:45.558401+07	ec6df8cf-cb47-4753-b1af-9aa2f7c7b30a	\N	["guest"]	pending	\N
perf-test-14-c3ab4dcc@example.com	Performance User 14	password	\N	\N	t	2025-08-22 17:35:45.558784+07	2025-08-22 17:35:45.558785+07	c3ab4dcc-dc63-4b9f-aa00-b773fd1216c1	\N	["guest"]	pending	\N
perf-test-15-0f3ea8e8@example.com	Performance User 15	password	\N	\N	t	2025-08-22 17:35:45.559333+07	2025-08-22 17:35:45.559333+07	0f3ea8e8-ecc7-46d2-9b8e-28bfbbc684ea	\N	["guest"]	pending	\N
perf-test-16-0810d284@example.com	Performance User 16	password	\N	\N	t	2025-08-22 17:35:45.559883+07	2025-08-22 17:35:45.559883+07	0810d284-ba46-436a-b09a-6c88fdc47afd	\N	["guest"]	pending	\N
perf-test-17-ff88a8ad@example.com	Performance User 17	password	\N	\N	t	2025-08-22 17:35:45.560428+07	2025-08-22 17:35:45.560429+07	ff88a8ad-2f48-4e73-8435-98e94a48d299	\N	["guest"]	pending	\N
perf-test-18-c12cb9b7@example.com	Performance User 18	password	\N	\N	t	2025-08-22 17:35:45.560802+07	2025-08-22 17:35:45.560802+07	c12cb9b7-5cfa-4c73-8af2-f86ede5524b9	\N	["guest"]	pending	\N
perf-test-19-8ea11e06@example.com	Performance User 19	password	\N	\N	t	2025-08-22 17:35:45.561184+07	2025-08-22 17:35:45.561184+07	8ea11e06-d51f-465d-b911-883fd30dd9a2	\N	["guest"]	pending	\N
perf-test-20-ce89f979@example.com	Performance User 20	password	\N	\N	t	2025-08-22 17:35:45.561554+07	2025-08-22 17:35:45.561554+07	ce89f979-96f4-4cb3-8884-af4ff61cd0a4	\N	["guest"]	pending	\N
perf-test-21-0304f976@example.com	Performance User 21	password	\N	\N	t	2025-08-22 17:35:45.561891+07	2025-08-22 17:35:45.561891+07	0304f976-e8ab-487c-a28a-9fec86a1434f	\N	["guest"]	pending	\N
perf-test-22-8b3a7187@example.com	Performance User 22	password	\N	\N	t	2025-08-22 17:35:45.562266+07	2025-08-22 17:35:45.562266+07	8b3a7187-ea55-4ad3-a6df-2dc8228dc78c	\N	["guest"]	pending	\N
perf-test-23-246bfb7e@example.com	Performance User 23	password	\N	\N	t	2025-08-22 17:35:45.562618+07	2025-08-22 17:35:45.562618+07	246bfb7e-d363-4753-9f4e-c209a28f4196	\N	["guest"]	pending	\N
perf-test-24-7870e4fc@example.com	Performance User 24	password	\N	\N	t	2025-08-22 17:35:45.562977+07	2025-08-22 17:35:45.562977+07	7870e4fc-09e1-4d25-8c8e-e0da10e89edb	\N	["guest"]	pending	\N
perf-test-25-adcc568d@example.com	Performance User 25	password	\N	\N	t	2025-08-22 17:35:45.563328+07	2025-08-22 17:35:45.563328+07	adcc568d-df8a-47b0-90d1-49c6102d5e76	\N	["guest"]	pending	\N
perf-test-26-19b90621@example.com	Performance User 26	password	\N	\N	t	2025-08-22 17:35:45.563704+07	2025-08-22 17:35:45.563704+07	19b90621-0a97-4a5e-927b-2190f4c46669	\N	["guest"]	pending	\N
perf-test-27-79c6d46f@example.com	Performance User 27	password	\N	\N	t	2025-08-22 17:35:45.564307+07	2025-08-22 17:35:45.564307+07	79c6d46f-0110-4682-8b8f-3f98e4851687	\N	["guest"]	pending	\N
perf-test-28-eb013a2f@example.com	Performance User 28	password	\N	\N	t	2025-08-22 17:35:45.564786+07	2025-08-22 17:35:45.564786+07	eb013a2f-6da6-44cb-8e9c-8a65ee8e1ab4	\N	["guest"]	pending	\N
perf-test-29-947be81c@example.com	Performance User 29	password	\N	\N	t	2025-08-22 17:35:45.565195+07	2025-08-22 17:35:45.565195+07	947be81c-863f-41c1-8d1b-d9683b808e0e	\N	["guest"]	pending	\N
perf-test-30-b9637c69@example.com	Performance User 30	password	\N	\N	t	2025-08-22 17:35:45.565713+07	2025-08-22 17:35:45.565713+07	b9637c69-cc37-49c5-bb81-51c994a17c41	\N	["guest"]	pending	\N
perf-test-31-cbe623dd@example.com	Performance User 31	password	\N	\N	t	2025-08-22 17:35:45.566171+07	2025-08-22 17:35:45.566171+07	cbe623dd-a188-4d1c-a753-e7bbde791723	\N	["guest"]	pending	\N
perf-test-32-8c662add@example.com	Performance User 32	password	\N	\N	t	2025-08-22 17:35:45.566654+07	2025-08-22 17:35:45.566654+07	8c662add-a743-4763-8b7c-1399a04c007e	\N	["guest"]	pending	\N
perf-test-33-92dbf474@example.com	Performance User 33	password	\N	\N	t	2025-08-22 17:35:45.567222+07	2025-08-22 17:35:45.567222+07	92dbf474-c9a7-453a-a4f2-5e89f99fbc5e	\N	["guest"]	pending	\N
perf-test-34-7dc9a2d5@example.com	Performance User 34	password	\N	\N	t	2025-08-22 17:35:45.568041+07	2025-08-22 17:35:45.568041+07	7dc9a2d5-47d9-48d1-9317-00424ec8642e	\N	["guest"]	pending	\N
perf-test-35-fc411e92@example.com	Performance User 35	password	\N	\N	t	2025-08-22 17:35:45.568715+07	2025-08-22 17:35:45.568715+07	fc411e92-a7b6-48d5-b247-87e82a297b5b	\N	["guest"]	pending	\N
perf-test-36-fa4b7d36@example.com	Performance User 36	password	\N	\N	t	2025-08-22 17:35:45.569355+07	2025-08-22 17:35:45.569355+07	fa4b7d36-e3c1-4305-ab74-9034d789d7a2	\N	["guest"]	pending	\N
perf-test-37-431815ed@example.com	Performance User 37	password	\N	\N	t	2025-08-22 17:35:45.569907+07	2025-08-22 17:35:45.569907+07	431815ed-2b31-4873-b751-0bbc7b673c94	\N	["guest"]	pending	\N
perf-test-38-be80cfdf@example.com	Performance User 38	password	\N	\N	t	2025-08-22 17:35:45.57052+07	2025-08-22 17:35:45.57052+07	be80cfdf-9532-421a-8b16-dc8b56cd309a	\N	["guest"]	pending	\N
perf-test-39-55a94e41@example.com	Performance User 39	password	\N	\N	t	2025-08-22 17:35:45.571085+07	2025-08-22 17:35:45.571086+07	55a94e41-e185-4e75-9648-9cd809af1f8b	\N	["guest"]	pending	\N
perf-test-40-2955f177@example.com	Performance User 40	password	\N	\N	t	2025-08-22 17:35:45.57151+07	2025-08-22 17:35:45.57151+07	2955f177-5732-47bb-ac0b-a395db934bf3	\N	["guest"]	pending	\N
perf-test-41-e50c8199@example.com	Performance User 41	password	\N	\N	t	2025-08-22 17:35:45.571929+07	2025-08-22 17:35:45.571929+07	e50c8199-e592-4fc5-a9d3-b7f7ecd14a81	\N	["guest"]	pending	\N
perf-test-42-d0ec1e2d@example.com	Performance User 42	password	\N	\N	t	2025-08-22 17:35:45.572318+07	2025-08-22 17:35:45.572318+07	d0ec1e2d-7a88-446a-bcc3-bd6bee9ee23b	\N	["guest"]	pending	\N
perf-test-43-3e3b8c54@example.com	Performance User 43	password	\N	\N	t	2025-08-22 17:35:45.572711+07	2025-08-22 17:35:45.572711+07	3e3b8c54-631e-4eae-a9e7-f3efeed65453	\N	["guest"]	pending	\N
perf-test-44-4058472b@example.com	Performance User 44	password	\N	\N	t	2025-08-22 17:35:45.573056+07	2025-08-22 17:35:45.573056+07	4058472b-4f78-446c-a685-f3f984589604	\N	["guest"]	pending	\N
perf-test-45-d640f5ab@example.com	Performance User 45	password	\N	\N	t	2025-08-22 17:35:45.573437+07	2025-08-22 17:35:45.573438+07	d640f5ab-e9f6-46d2-8c2e-243b86ad61f3	\N	["guest"]	pending	\N
perf-test-46-9b478293@example.com	Performance User 46	password	\N	\N	t	2025-08-22 17:35:45.573788+07	2025-08-22 17:35:45.573788+07	9b478293-b7ea-4e20-b8e2-c79366b2dc39	\N	["guest"]	pending	\N
perf-test-47-05d3f9dd@example.com	Performance User 47	password	\N	\N	t	2025-08-22 17:35:45.574163+07	2025-08-22 17:35:45.574163+07	05d3f9dd-2a09-4b3e-bab7-428cd13a0b9e	\N	["guest"]	pending	\N
perf-test-48-5178619f@example.com	Performance User 48	password	\N	\N	t	2025-08-22 17:35:45.574645+07	2025-08-22 17:35:45.574645+07	5178619f-c5a3-4790-9727-7753ede6f349	\N	["guest"]	pending	\N
perf-test-49-ba83d4fa@example.com	Performance User 49	password	\N	\N	t	2025-08-22 17:35:45.575153+07	2025-08-22 17:35:45.575153+07	ba83d4fa-6c76-46d6-b74c-cb1a556da31b	\N	["guest"]	pending	\N
user-4-feb4f80c@example.com	User 4	hashedpassword	\N	\N	t	2025-08-29 20:22:55.144954+07	2025-08-29 20:22:55.144954+07	feb4f80c-b854-4783-b230-8ddd453ce845	\N	["guest"]	pending	\N
user-7-dd0d458c@example.com	User 7	hashedpassword	\N	\N	t	2025-08-29 20:22:55.153066+07	2025-08-29 20:22:55.153066+07	dd0d458c-a805-4848-9995-e253ef996770	\N	["guest"]	pending	\N
user-9-3e900335@example.com	User 9	hashedpassword	\N	\N	t	2025-08-29 20:22:55.155362+07	2025-08-29 20:22:55.155362+07	3e900335-d92d-4ddd-a6ff-bd5036ff40a7	\N	["guest"]	pending	\N
user-11-bf746002@example.com	User 11	hashedpassword	\N	\N	t	2025-08-29 20:22:55.15654+07	2025-08-29 20:22:55.156541+07	bf746002-58a2-4d5d-9ad0-15426e5951fe	\N	["guest"]	pending	\N
user-13-6dbbd58d@example.com	User 13	hashedpassword	\N	\N	t	2025-08-29 20:22:55.157584+07	2025-08-29 20:22:55.157584+07	6dbbd58d-8901-4d2f-acf0-44f0e9fcde7f	\N	["guest"]	pending	\N
user-14-8a24d787@example.com	User 14	hashedpassword	\N	\N	t	2025-08-29 20:22:55.158107+07	2025-08-29 20:22:55.158107+07	8a24d787-f7ac-4ce4-8acf-ea18665a6913	\N	["guest"]	pending	\N
user-19-174239f9@example.com	User 19	hashedpassword	\N	\N	t	2025-08-29 20:22:55.16314+07	2025-08-29 20:22:55.16314+07	174239f9-c944-420d-9237-ac31cbb3e2db	\N	["guest"]	pending	\N
user-23-4171a9ad@example.com	User 23	hashedpassword	\N	\N	t	2025-08-29 20:22:55.165224+07	2025-08-29 20:22:55.165224+07	4171a9ad-00cf-4ae3-86b5-3576f4319e49	\N	["guest"]	pending	\N
user-24-7b26da58@example.com	User 24	hashedpassword	\N	\N	t	2025-08-29 20:22:55.165638+07	2025-08-29 20:22:55.165638+07	7b26da58-2074-48e4-85fe-db53ca19f4f7	\N	["guest"]	pending	\N
user-26-21e3b369@example.com	User 26	hashedpassword	\N	\N	t	2025-08-29 20:22:55.166469+07	2025-08-29 20:22:55.166469+07	21e3b369-55a0-47f6-8b1a-83c54bbd3e65	\N	["guest"]	pending	\N
user-27-4b98457c@example.com	User 27	hashedpassword	\N	\N	t	2025-08-29 20:22:55.167037+07	2025-08-29 20:22:55.167037+07	4b98457c-8e2e-4161-a113-7c146514d0af	\N	["guest"]	pending	\N
user-30-b88769fe@example.com	User 30	hashedpassword	\N	\N	t	2025-08-29 20:22:55.16929+07	2025-08-29 20:22:55.16929+07	b88769fe-4f40-4495-bfb7-d0ed273ba0c9	\N	["guest"]	pending	\N
user-38-5f0a6993@example.com	User 38	hashedpassword	\N	\N	t	2025-08-29 20:22:55.173419+07	2025-08-29 20:22:55.173419+07	5f0a6993-1763-4242-93df-d34b38959258	\N	["guest"]	pending	\N
user-39-3097a3c6@example.com	User 39	hashedpassword	\N	\N	t	2025-08-29 20:22:55.173861+07	2025-08-29 20:22:55.173862+07	3097a3c6-7ffe-4126-af1a-c3a954d4407d	\N	["guest"]	pending	\N
user-42-f3b54526@example.com	User 42	hashedpassword	\N	\N	t	2025-08-29 20:22:55.17528+07	2025-08-29 20:22:55.17528+07	f3b54526-05cd-47c4-8315-8311be664bf3	\N	["guest"]	pending	\N
user-43-e1835b3b@example.com	User 43	hashedpassword	\N	\N	t	2025-08-29 20:22:55.175737+07	2025-08-29 20:22:55.175737+07	e1835b3b-3ac7-4b94-b6bf-a8681f52ded2	\N	["guest"]	pending	\N
user-46-f34d6b8d@example.com	User 46	hashedpassword	\N	\N	t	2025-08-29 20:22:55.179067+07	2025-08-29 20:22:55.179067+07	f34d6b8d-960c-48b9-96a6-a03bdc2378eb	\N	["guest"]	pending	\N
user-56-68ae519d@example.com	User 56	hashedpassword	\N	\N	t	2025-08-29 20:22:55.183743+07	2025-08-29 20:22:55.183743+07	68ae519d-0299-45e1-b5ff-eca75c73d1a8	\N	["guest"]	pending	\N
user-68-0cd96bec@example.com	User 68	hashedpassword	\N	\N	t	2025-08-29 20:22:55.190356+07	2025-08-29 20:22:55.190356+07	0cd96bec-ddf5-40ac-8770-9821802aecf6	\N	["guest"]	pending	\N
user-81-b540e861@example.com	User 81	hashedpassword	\N	\N	t	2025-08-29 20:22:55.199155+07	2025-08-29 20:22:55.199155+07	b540e861-dbcd-4a8c-b3f3-2e82723f2d4c	\N	["guest"]	pending	\N
user-84-d7eb44fa@example.com	User 84	hashedpassword	\N	\N	t	2025-08-29 20:22:55.200452+07	2025-08-29 20:22:55.200452+07	d7eb44fa-db27-4571-8951-2f2ed51db9d4	\N	["guest"]	pending	\N
user-88-85f1e77a@example.com	User 88	hashedpassword	\N	\N	t	2025-08-29 20:22:55.202518+07	2025-08-29 20:22:55.202518+07	85f1e77a-73d0-447c-8cce-c38623d7e4c3	\N	["guest"]	pending	\N
user-92-ad7ae39c@example.com	User 92	hashedpassword	\N	\N	t	2025-08-29 20:22:55.204804+07	2025-08-29 20:22:55.204804+07	ad7ae39c-3a8c-4521-af61-deffa5683cde	\N	["guest"]	pending	\N
user-95-bf6a55a1@example.com	User 95	hashedpassword	\N	\N	t	2025-08-29 20:22:55.206129+07	2025-08-29 20:22:55.206129+07	bf6a55a1-2f85-47d2-b679-8faace1a7d57	\N	["guest"]	pending	\N
concurrent-user-0-ea2a964d@example.com	Concurrent User 0	password	\N	\N	t	2025-08-29 20:22:55.46934+07	2025-08-29 20:22:55.46934+07	ea2a964d-6e18-48af-8b51-9721a9fad147	\N	["guest"]	pending	\N
concurrent-user-4-d01b089d@example.com	Concurrent User 4	password	\N	\N	t	2025-08-29 20:22:55.469212+07	2025-08-29 20:22:55.469212+07	d01b089d-24ab-42d1-8671-76f15b51e932	\N	["guest"]	pending	\N
perf-test-0-c4d3ee35@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:22:55.61451+07	2025-08-29 20:22:55.614511+07	c4d3ee35-fae3-46cd-bfbb-c855cd4a3628	\N	["guest"]	pending	\N
perf-test-1-75974820@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:22:55.615885+07	2025-08-29 20:22:55.615886+07	75974820-9e2e-4335-8177-4bb6fc9d1700	\N	["guest"]	pending	\N
perf-test-2-3d8c8717@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:22:55.616291+07	2025-08-29 20:22:55.616291+07	3d8c8717-606d-45e8-9134-8cf639959180	\N	["guest"]	pending	\N
perf-test-3-01374325@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:22:55.616763+07	2025-08-29 20:22:55.616763+07	01374325-63ec-45c6-bf3a-60cfc6b69cc8	\N	["guest"]	pending	\N
perf-test-4-91af982b@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:22:55.617403+07	2025-08-29 20:22:55.617403+07	91af982b-3d67-4ba0-8c35-c60f93295b7d	\N	["guest"]	pending	\N
perf-test-5-6cb2778a@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:22:55.617902+07	2025-08-29 20:22:55.617903+07	6cb2778a-c0c0-491e-9cd0-433733c7033d	\N	["guest"]	pending	\N
perf-test-6-a91708d3@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:22:55.618428+07	2025-08-29 20:22:55.618428+07	a91708d3-ecc0-4dc5-ab13-2546c6e4e672	\N	["guest"]	pending	\N
perf-test-7-3a6e69fa@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:22:55.618876+07	2025-08-29 20:22:55.618876+07	3a6e69fa-2181-4441-be95-b7b3fe90f9ba	\N	["guest"]	pending	\N
perf-test-8-208748f3@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:22:55.619496+07	2025-08-29 20:22:55.619496+07	208748f3-562f-492f-b8fd-c5fdb26fc804	\N	["guest"]	pending	\N
perf-test-9-be1f31c4@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:22:55.620267+07	2025-08-29 20:22:55.620267+07	be1f31c4-b63b-4ead-85f6-cf7202a3cfdd	\N	["guest"]	pending	\N
perf-test-10-3af755e4@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:22:55.620874+07	2025-08-29 20:22:55.620874+07	3af755e4-30a6-48c8-9ab3-b9a2d221a5e4	\N	["guest"]	pending	\N
perf-test-11-a07cf0d2@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:22:55.621423+07	2025-08-29 20:22:55.621423+07	a07cf0d2-b3d1-4bd1-953f-7d070e7b84b0	\N	["guest"]	pending	\N
perf-test-12-bfb47db7@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:22:55.622424+07	2025-08-29 20:22:55.622424+07	bfb47db7-7cc7-4983-a57c-344c4103253c	\N	["guest"]	pending	\N
perf-test-13-e2516ff0@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:22:55.622887+07	2025-08-29 20:22:55.622887+07	e2516ff0-2ac3-4979-93aa-2c0f5d505d89	\N	["guest"]	pending	\N
perf-test-14-1b4399f4@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:22:55.623299+07	2025-08-29 20:22:55.623299+07	1b4399f4-9e37-4591-983a-588bc4b135ca	\N	["guest"]	pending	\N
perf-test-15-17d08ae5@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:22:55.623685+07	2025-08-29 20:22:55.623685+07	17d08ae5-0d45-408c-af46-02eb72eb5531	\N	["guest"]	pending	\N
perf-test-16-34557c30@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:22:55.624161+07	2025-08-29 20:22:55.624161+07	34557c30-7676-4ed2-aeab-b1e911016b82	\N	["guest"]	pending	\N
perf-test-17-71171fa5@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:22:55.624617+07	2025-08-29 20:22:55.624617+07	71171fa5-e8dd-4a39-a10c-ed8258643ba6	\N	["guest"]	pending	\N
perf-test-18-f03c2d38@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:22:55.62511+07	2025-08-29 20:22:55.625111+07	f03c2d38-7614-403c-a593-6786279c6a6a	\N	["guest"]	pending	\N
perf-test-19-4521859e@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:22:55.625615+07	2025-08-29 20:22:55.625615+07	4521859e-0786-499f-98dd-7a3effaa4f4f	\N	["guest"]	pending	\N
perf-test-20-9e6ea456@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:22:55.62648+07	2025-08-29 20:22:55.62648+07	9e6ea456-70bd-4a3c-aa68-46ace6721b38	\N	["guest"]	pending	\N
perf-test-21-e8c507f8@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:22:55.627331+07	2025-08-29 20:22:55.627331+07	e8c507f8-e322-4c93-a840-3c0020fc2d1d	\N	["guest"]	pending	\N
perf-test-22-eb8ed0df@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:22:55.628028+07	2025-08-29 20:22:55.628029+07	eb8ed0df-219c-4c10-8be7-f5ac2927311a	\N	["guest"]	pending	\N
perf-test-23-f7ba1282@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:22:55.628683+07	2025-08-29 20:22:55.628683+07	f7ba1282-8626-40c3-b4e0-4c327c0840b9	\N	["guest"]	pending	\N
perf-test-24-10ee65d6@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:22:55.62931+07	2025-08-29 20:22:55.62931+07	10ee65d6-1a24-4d70-9456-5b81af6404dc	\N	["guest"]	pending	\N
perf-test-25-ba19d5ab@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:22:55.630016+07	2025-08-29 20:22:55.630016+07	ba19d5ab-8f70-4b92-8f10-7f04ae7cb09a	\N	["guest"]	pending	\N
perf-test-26-89234132@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:22:55.630666+07	2025-08-29 20:22:55.630667+07	89234132-0e6d-4636-a4b2-6b7aab0648d7	\N	["guest"]	pending	\N
perf-test-27-62699cab@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:22:55.631093+07	2025-08-29 20:22:55.631093+07	62699cab-6765-4937-9991-a1a1fdaf0376	\N	["guest"]	pending	\N
perf-test-28-4d576888@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:22:55.63148+07	2025-08-29 20:22:55.63148+07	4d576888-ba11-4fe4-92f3-2a415a8ceae0	\N	["guest"]	pending	\N
perf-test-29-55e7c8a6@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:22:55.631919+07	2025-08-29 20:22:55.631919+07	55e7c8a6-b46c-4a53-a2a4-4510a85a01f0	\N	["guest"]	pending	\N
perf-test-30-1ba1ebcc@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:22:55.632291+07	2025-08-29 20:22:55.632291+07	1ba1ebcc-c8f8-424e-9033-d34f66cf79b4	\N	["guest"]	pending	\N
perf-test-31-ece7807b@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:22:55.632656+07	2025-08-29 20:22:55.632656+07	ece7807b-1f3c-4be2-8c52-e7fddbd4d7af	\N	["guest"]	pending	\N
perf-test-32-e2fa81a6@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:22:55.633039+07	2025-08-29 20:22:55.633039+07	e2fa81a6-4f3e-4666-8fd4-fda4efb811af	\N	["guest"]	pending	\N
perf-test-33-3a4e3b7f@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:22:55.633553+07	2025-08-29 20:22:55.633553+07	3a4e3b7f-f075-4688-897c-df4ebfccd9ed	\N	["guest"]	pending	\N
perf-test-34-94ccdd10@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:22:55.634015+07	2025-08-29 20:22:55.634015+07	94ccdd10-8b01-4021-a913-bff1886a9c05	\N	["guest"]	pending	\N
perf-test-35-6c062bd8@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:22:55.634451+07	2025-08-29 20:22:55.634451+07	6c062bd8-c6d4-41f2-8f69-5783ae63c9c7	\N	["guest"]	pending	\N
perf-test-36-e71c9339@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:22:55.634876+07	2025-08-29 20:22:55.634876+07	e71c9339-804b-4321-95bf-df5c7df73448	\N	["guest"]	pending	\N
perf-test-37-80379343@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:22:55.635377+07	2025-08-29 20:22:55.635377+07	80379343-562c-4f29-828e-394d330f670d	\N	["guest"]	pending	\N
perf-test-38-5d490116@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:22:55.635957+07	2025-08-29 20:22:55.635957+07	5d490116-c0bc-4aea-8edf-c93987405709	\N	["guest"]	pending	\N
perf-test-39-711e8285@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:22:55.63646+07	2025-08-29 20:22:55.636461+07	711e8285-de39-42bc-bde7-f38ba428d2f4	\N	["guest"]	pending	\N
perf-test-40-6d585f09@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:22:55.636969+07	2025-08-29 20:22:55.63697+07	6d585f09-b83c-401c-bb09-ebb559128f15	\N	["guest"]	pending	\N
perf-test-41-17c91c75@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:22:55.637454+07	2025-08-29 20:22:55.637454+07	17c91c75-88a9-4bad-bf09-34ea8ab3fcfb	\N	["guest"]	pending	\N
perf-test-42-3c931ac4@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:22:55.637946+07	2025-08-29 20:22:55.637946+07	3c931ac4-0d59-4e2f-8e03-45b885a2cc70	\N	["guest"]	pending	\N
perf-test-43-aedfe58b@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:22:55.63837+07	2025-08-29 20:22:55.63837+07	aedfe58b-eed1-497a-b65e-b8693432f475	\N	["guest"]	pending	\N
perf-test-44-e272cf50@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:22:55.638751+07	2025-08-29 20:22:55.638751+07	e272cf50-02f0-43d6-a813-bca82cb87b35	\N	["guest"]	pending	\N
perf-test-45-81468d2a@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:22:55.639195+07	2025-08-29 20:22:55.639195+07	81468d2a-00a4-4573-873f-602069cf9e04	\N	["guest"]	pending	\N
perf-test-46-bf048be9@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:22:55.63966+07	2025-08-29 20:22:55.63966+07	bf048be9-2aa9-4496-8f15-6a593798bf2b	\N	["guest"]	pending	\N
perf-test-47-6d421f95@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:22:55.640058+07	2025-08-29 20:22:55.640058+07	6d421f95-2087-4882-8227-acc9aebbbe5b	\N	["guest"]	pending	\N
perf-test-48-428a6f84@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:22:55.640468+07	2025-08-29 20:22:55.640468+07	428a6f84-d570-4668-9e56-06d272273f0e	\N	["guest"]	pending	\N
perf-test-49-2b7d17f8@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:22:55.640879+07	2025-08-29 20:22:55.640879+07	2b7d17f8-63b0-4c31-8fad-3ffd913f1582	\N	["guest"]	pending	\N
user-0-bac3a142@example.com	User 0	hashedpassword	\N	\N	t	2025-08-29 20:59:13.119827+07	2025-08-29 20:59:13.119827+07	bac3a142-70bc-4bbc-978b-7a02f4792820	\N	["guest"]	pending	\N
user-2-7b49febf@example.com	User 2	hashedpassword	\N	\N	t	2025-08-29 20:59:13.130437+07	2025-08-29 20:59:13.130438+07	7b49febf-f897-4662-8c59-1f3653767aad	\N	["guest"]	pending	\N
user-4-aff4c4de@example.com	User 4	hashedpassword	\N	\N	t	2025-08-29 20:59:13.133107+07	2025-08-29 20:59:13.133107+07	aff4c4de-4d88-44e3-b7fb-71dd7a0d39d5	\N	["guest"]	pending	\N
user-7-84c49b8c@example.com	User 7	hashedpassword	\N	\N	t	2025-08-29 20:59:13.138931+07	2025-08-29 20:59:13.138931+07	84c49b8c-3279-4d71-a277-5f989638f858	\N	["guest"]	pending	\N
user-12-26362dcc@example.com	User 12	hashedpassword	\N	\N	t	2025-08-29 20:59:13.145989+07	2025-08-29 20:59:13.145989+07	26362dcc-9a39-4080-9e26-3a9b2da0a83a	\N	["guest"]	pending	\N
user-13-dd2f4a62@example.com	User 13	hashedpassword	\N	\N	t	2025-08-29 20:59:13.146655+07	2025-08-29 20:59:13.146655+07	dd2f4a62-9c53-4625-b785-57fc189184b0	\N	["guest"]	pending	\N
user-23-e2933da4@example.com	User 23	hashedpassword	\N	\N	t	2025-08-29 20:59:13.151558+07	2025-08-29 20:59:13.151558+07	e2933da4-2313-47ff-a564-ea629731f9e4	\N	["guest"]	pending	\N
user-28-a9cd1417@example.com	User 28	hashedpassword	\N	\N	t	2025-08-29 20:59:13.155322+07	2025-08-29 20:59:13.155323+07	a9cd1417-ace0-45f0-a719-36d5cc679f4d	\N	["guest"]	pending	\N
user-29-00e14f1e@example.com	User 29	hashedpassword	\N	\N	t	2025-08-29 20:59:13.157158+07	2025-08-29 20:59:13.157158+07	00e14f1e-0b02-452e-9935-6b99b1b89bb6	\N	["guest"]	pending	\N
user-35-936022e5@example.com	User 35	hashedpassword	\N	\N	t	2025-08-29 20:59:13.161689+07	2025-08-29 20:59:13.161689+07	936022e5-eecb-4d05-a58a-3aac3af20408	\N	["guest"]	pending	\N
user-36-3c5de722@example.com	User 36	hashedpassword	\N	\N	t	2025-08-29 20:59:13.163332+07	2025-08-29 20:59:13.163332+07	3c5de722-c01e-4d4f-bdd3-4cc6af4f5585	\N	["guest"]	pending	\N
user-38-ac400f66@example.com	User 38	hashedpassword	\N	\N	t	2025-08-29 20:59:13.164407+07	2025-08-29 20:59:13.164407+07	ac400f66-16b9-40f8-9e62-93cbad9cdf2e	\N	["guest"]	pending	\N
user-40-177007d3@example.com	User 40	hashedpassword	\N	\N	t	2025-08-29 20:59:13.165308+07	2025-08-29 20:59:13.165308+07	177007d3-3c69-43ff-a8a9-81d9ddadecbd	\N	["guest"]	pending	\N
user-48-8e4eafd1@example.com	User 48	hashedpassword	\N	\N	t	2025-08-29 20:59:13.16953+07	2025-08-29 20:59:13.16953+07	8e4eafd1-cd98-4b5b-af37-e230c0da4ccf	\N	["guest"]	pending	\N
user-55-d8b2e48e@example.com	User 55	hashedpassword	\N	\N	t	2025-08-29 20:59:13.176082+07	2025-08-29 20:59:13.176082+07	d8b2e48e-3b53-4f04-9834-e7a61b492e38	\N	["guest"]	pending	\N
user-67-16447775@example.com	User 67	hashedpassword	\N	\N	t	2025-08-29 20:59:13.182005+07	2025-08-29 20:59:13.182005+07	16447775-a6fb-4610-b630-087207f8e971	\N	["guest"]	pending	\N
user-70-732533b8@example.com	User 70	hashedpassword	\N	\N	t	2025-08-29 20:59:13.183129+07	2025-08-29 20:59:13.183129+07	732533b8-8bd9-473d-93ed-33c63d536ca6	\N	["guest"]	pending	\N
user-76-1fd2b92a@example.com	User 76	hashedpassword	\N	\N	t	2025-08-29 20:59:13.185924+07	2025-08-29 20:59:13.185925+07	1fd2b92a-5e3c-4127-935e-6138c81d15da	\N	["guest"]	pending	\N
user-77-13cefe72@example.com	User 77	hashedpassword	\N	\N	t	2025-08-29 20:59:13.186454+07	2025-08-29 20:59:13.186454+07	13cefe72-3867-432a-b54e-e928d3349daf	\N	["guest"]	pending	\N
user-81-680ee9d8@example.com	User 81	hashedpassword	\N	\N	t	2025-08-29 20:59:13.191561+07	2025-08-29 20:59:13.191561+07	680ee9d8-d744-4dde-a826-00fd30303c4a	\N	["guest"]	pending	\N
user-82-06d989db@example.com	User 82	hashedpassword	\N	\N	t	2025-08-29 20:59:13.192138+07	2025-08-29 20:59:13.192138+07	06d989db-c26d-4114-8ac9-6aa4a34abf98	\N	["guest"]	pending	\N
user-83-9ef6e8f2@example.com	User 83	hashedpassword	\N	\N	t	2025-08-29 20:59:13.192812+07	2025-08-29 20:59:13.192813+07	9ef6e8f2-e0ed-4207-9320-7f276f743983	\N	["guest"]	pending	\N
user-85-5583f5af@example.com	User 85	hashedpassword	\N	\N	t	2025-08-29 20:59:13.194461+07	2025-08-29 20:59:13.194461+07	5583f5af-ffec-478c-9c01-8885685c31c1	\N	["guest"]	pending	\N
user-93-2f3d57c8@example.com	User 93	hashedpassword	\N	\N	t	2025-08-29 20:59:13.198425+07	2025-08-29 20:59:13.198425+07	2f3d57c8-7948-475b-b1f9-12cc24455766	\N	["guest"]	pending	\N
user-94-bb2eb9fc@example.com	User 94	hashedpassword	\N	\N	t	2025-08-29 20:59:13.198793+07	2025-08-29 20:59:13.198793+07	bb2eb9fc-690e-4e81-bf50-dfe54d4233cd	\N	["guest"]	pending	\N
user-97-1d24bde5@example.com	User 97	hashedpassword	\N	\N	t	2025-08-29 20:59:13.200027+07	2025-08-29 20:59:13.200027+07	1d24bde5-b61b-43df-b15f-c0c6016c7dde	\N	["guest"]	pending	\N
concurrent-user-4-fef44321@example.com	Concurrent User 4	password	\N	\N	t	2025-08-29 20:59:13.418706+07	2025-08-29 20:59:13.418706+07	fef44321-06b7-4a74-aebe-ae95df3dff2a	\N	["guest"]	pending	\N
concurrent-user-0-a852587a@example.com	Concurrent User 0	password	\N	\N	t	2025-08-29 20:59:13.418636+07	2025-08-29 20:59:13.418637+07	a852587a-e30f-42cb-b0de-2075aa0f9cb4	\N	["guest"]	pending	\N
perf-test-0-9e0d043e@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:59:13.612035+07	2025-08-29 20:59:13.612035+07	9e0d043e-f28b-41e7-9ba0-4a42d8bdcb3b	\N	["guest"]	pending	\N
perf-test-1-97bc9d6b@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:59:13.614142+07	2025-08-29 20:59:13.614142+07	97bc9d6b-11c6-47b4-8110-aab29290cb10	\N	["guest"]	pending	\N
perf-test-2-87a33c0c@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:59:13.6149+07	2025-08-29 20:59:13.6149+07	87a33c0c-7143-4078-9efc-2b44636f57d7	\N	["guest"]	pending	\N
perf-test-3-e52607f8@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:59:13.615645+07	2025-08-29 20:59:13.615645+07	e52607f8-82e0-4ab7-991b-2141f804998e	\N	["guest"]	pending	\N
perf-test-4-a3ac65d4@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:59:13.616676+07	2025-08-29 20:59:13.616676+07	a3ac65d4-230b-4cbe-a2c7-d78db04c0f59	\N	["guest"]	pending	\N
perf-test-5-29faa426@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:59:13.617285+07	2025-08-29 20:59:13.617285+07	29faa426-a2b2-4ec8-9414-2d2d352cd54d	\N	["guest"]	pending	\N
perf-test-6-567ccde8@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:59:13.617913+07	2025-08-29 20:59:13.617914+07	567ccde8-649f-4edf-b9f0-07ee5be425c9	\N	["guest"]	pending	\N
perf-test-7-507334af@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:59:13.618562+07	2025-08-29 20:59:13.618562+07	507334af-ec78-445d-8779-4e2dfdb92435	\N	["guest"]	pending	\N
perf-test-8-21afe00f@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:59:13.619423+07	2025-08-29 20:59:13.619423+07	21afe00f-b141-4c4a-bc41-4a07277fcf26	\N	["guest"]	pending	\N
perf-test-9-cf96d29a@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:59:13.620068+07	2025-08-29 20:59:13.620068+07	cf96d29a-c477-4f11-866f-deb9634e3212	\N	["guest"]	pending	\N
perf-test-10-1c99ea64@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:59:13.621019+07	2025-08-29 20:59:13.621019+07	1c99ea64-f597-4bc9-a256-0a948373ab84	\N	["guest"]	pending	\N
perf-test-11-e96ada6a@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:59:13.622458+07	2025-08-29 20:59:13.622458+07	e96ada6a-68fa-4dfc-966f-2dcdaf7ba8ef	\N	["guest"]	pending	\N
perf-test-12-a357782e@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:59:13.625101+07	2025-08-29 20:59:13.625101+07	a357782e-3d1f-4bc6-9203-b7424af1cc65	\N	["guest"]	pending	\N
perf-test-13-b08fea3f@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:59:13.625785+07	2025-08-29 20:59:13.625785+07	b08fea3f-cb24-475a-a98a-ce6a994ce27b	\N	["guest"]	pending	\N
perf-test-14-7ff91de5@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:59:13.626532+07	2025-08-29 20:59:13.626533+07	7ff91de5-a1dc-4bde-9c38-0f736f755cfc	\N	["guest"]	pending	\N
perf-test-15-374d4c22@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:59:13.627369+07	2025-08-29 20:59:13.627369+07	374d4c22-78e1-4d15-9a6c-a623a070bc18	\N	["guest"]	pending	\N
perf-test-16-42933d7b@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:59:13.628335+07	2025-08-29 20:59:13.628335+07	42933d7b-c29e-4316-8f1c-79d47a0905b6	\N	["guest"]	pending	\N
perf-test-17-2bb70a34@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:59:13.629251+07	2025-08-29 20:59:13.629251+07	2bb70a34-b2af-4f3e-9177-92819938ea8d	\N	["guest"]	pending	\N
perf-test-18-4df5fe9c@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:59:13.630013+07	2025-08-29 20:59:13.630013+07	4df5fe9c-752e-4c32-b266-8e72435242af	\N	["guest"]	pending	\N
perf-test-19-9aae28c1@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:59:13.63071+07	2025-08-29 20:59:13.63071+07	9aae28c1-21e9-4f66-bfe2-299b77048b02	\N	["guest"]	pending	\N
perf-test-20-c1fa54a3@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:59:13.631298+07	2025-08-29 20:59:13.631298+07	c1fa54a3-c600-45ec-90b3-9bdfcb786f18	\N	["guest"]	pending	\N
perf-test-21-7e07cc4f@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:59:13.63184+07	2025-08-29 20:59:13.63184+07	7e07cc4f-8779-428f-b689-62d9b2c8ada4	\N	["guest"]	pending	\N
perf-test-22-58a730aa@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:59:13.632424+07	2025-08-29 20:59:13.632424+07	58a730aa-d9da-498a-84df-d140d49ed57b	\N	["guest"]	pending	\N
perf-test-23-d37b355d@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:59:13.63295+07	2025-08-29 20:59:13.63295+07	d37b355d-ef3e-4f35-b931-cd9a897ae4f5	\N	["guest"]	pending	\N
perf-test-24-4e7b08ce@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:59:13.6335+07	2025-08-29 20:59:13.6335+07	4e7b08ce-397f-41c6-8494-ec136423d41a	\N	["guest"]	pending	\N
perf-test-25-87d15cef@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:59:13.633983+07	2025-08-29 20:59:13.633983+07	87d15cef-0f56-4189-af5e-a2ba118eeb49	\N	["guest"]	pending	\N
perf-test-26-8f7ebcbc@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:59:13.634476+07	2025-08-29 20:59:13.634476+07	8f7ebcbc-a7d7-4849-8334-ff8897b1e90b	\N	["guest"]	pending	\N
perf-test-27-a32469f5@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:59:13.635017+07	2025-08-29 20:59:13.635017+07	a32469f5-d5bb-42a0-8338-0c1847664e3e	\N	["guest"]	pending	\N
perf-test-28-fe5189bd@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:59:13.63555+07	2025-08-29 20:59:13.63555+07	fe5189bd-d5b9-4b28-a0cf-c0ee0a589873	\N	["guest"]	pending	\N
perf-test-29-8ee1c3b1@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:59:13.636174+07	2025-08-29 20:59:13.636174+07	8ee1c3b1-e95c-4161-9195-5bb2357b27ff	\N	["guest"]	pending	\N
perf-test-30-438319a0@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:59:13.63671+07	2025-08-29 20:59:13.63671+07	438319a0-78ed-4bb1-8ca1-40091a241ade	\N	["guest"]	pending	\N
perf-test-31-a81073cd@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:59:13.637601+07	2025-08-29 20:59:13.637601+07	a81073cd-77ff-4bd2-9148-fa9af36f3e19	\N	["guest"]	pending	\N
perf-test-32-d84db20a@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:59:13.638634+07	2025-08-29 20:59:13.638634+07	d84db20a-f310-49a1-8b9c-eda29c9cfe5a	\N	["guest"]	pending	\N
perf-test-33-31aa0e0a@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:59:13.640319+07	2025-08-29 20:59:13.64032+07	31aa0e0a-02d5-4ca8-abb6-ca01707d3f4c	\N	["guest"]	pending	\N
perf-test-34-56420a38@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:59:13.641643+07	2025-08-29 20:59:13.641643+07	56420a38-3be4-4b92-a35e-d3886a93e03f	\N	["guest"]	pending	\N
perf-test-35-1563ec8b@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:59:13.642242+07	2025-08-29 20:59:13.642242+07	1563ec8b-c9bd-4a66-9c8d-5ebea97c9a44	\N	["guest"]	pending	\N
perf-test-36-656c0163@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:59:13.642947+07	2025-08-29 20:59:13.642947+07	656c0163-7e6b-40f7-98a7-4dde3a227491	\N	["guest"]	pending	\N
perf-test-37-cfc8db69@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:59:13.6437+07	2025-08-29 20:59:13.6437+07	cfc8db69-acaf-42c1-8842-22863515817d	\N	["guest"]	pending	\N
perf-test-38-050c6657@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:59:13.644391+07	2025-08-29 20:59:13.644391+07	050c6657-eede-4824-8d96-a9077772cbe3	\N	["guest"]	pending	\N
perf-test-39-b2fa88ca@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:59:13.645181+07	2025-08-29 20:59:13.645182+07	b2fa88ca-27b1-4a58-b98c-d548867452d5	\N	["guest"]	pending	\N
perf-test-40-e8dcd5e7@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:59:13.645776+07	2025-08-29 20:59:13.645776+07	e8dcd5e7-d978-435a-9038-3b87e1e7caa9	\N	["guest"]	pending	\N
perf-test-41-4e90cd08@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:59:13.646211+07	2025-08-29 20:59:13.646211+07	4e90cd08-ffd1-40a1-b2a4-f0589d1c5a6a	\N	["guest"]	pending	\N
perf-test-42-4dda8f32@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:59:13.646663+07	2025-08-29 20:59:13.646663+07	4dda8f32-db59-4be5-bbc9-b2e67299a896	\N	["guest"]	pending	\N
perf-test-43-f4766feb@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:59:13.647072+07	2025-08-29 20:59:13.647072+07	f4766feb-50bb-4dd1-8f5f-815e31c29eda	\N	["guest"]	pending	\N
perf-test-44-47966f66@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:59:13.647499+07	2025-08-29 20:59:13.647499+07	47966f66-1dc7-48b4-bdc4-f601ccf4674b	\N	["guest"]	pending	\N
perf-test-45-a5fa6cb6@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:59:13.647958+07	2025-08-29 20:59:13.647958+07	a5fa6cb6-9ec3-4de2-8267-5c5de595751d	\N	["guest"]	pending	\N
perf-test-46-e01299c0@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:59:13.648366+07	2025-08-29 20:59:13.648366+07	e01299c0-9c35-404d-a250-3e5a1f46c6e5	\N	["guest"]	pending	\N
perf-test-47-f8dbbde9@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:59:13.648757+07	2025-08-29 20:59:13.648757+07	f8dbbde9-530e-4fce-a9ef-3347759656e3	\N	["guest"]	pending	\N
perf-test-48-9e5c5a42@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:59:13.649125+07	2025-08-29 20:59:13.649126+07	9e5c5a42-4901-435f-9d0a-5e3324b1e3e8	\N	["guest"]	pending	\N
perf-test-49-6e2924f3@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:59:13.64949+07	2025-08-29 20:59:13.649491+07	6e2924f3-abd4-4a5c-acb0-d4c402d60df3	\N	["guest"]	pending	\N
user-9-48ac04ed@example.com	User 9	hashedpassword	\N	\N	t	2025-08-29 21:59:39.978662+07	2025-08-29 21:59:39.978662+07	48ac04ed-bbb8-4dbf-bd8a-4c82ca8edae7	\N	["guest"]	pending	\N
user-12-2c7e2b1d@example.com	User 12	hashedpassword	\N	\N	t	2025-08-29 21:59:39.987856+07	2025-08-29 21:59:39.987856+07	2c7e2b1d-bc07-465e-9bb4-8c7126eda212	\N	["guest"]	pending	\N
user-13-becaa262@example.com	User 13	hashedpassword	\N	\N	t	2025-08-29 21:59:39.9896+07	2025-08-29 21:59:39.9896+07	becaa262-97c2-4218-a3d6-818e778363e6	\N	["guest"]	pending	\N
user-17-f56702a7@example.com	User 17	hashedpassword	\N	\N	t	2025-08-29 21:59:39.993907+07	2025-08-29 21:59:39.993908+07	f56702a7-e27d-46ff-803d-e60a513785c3	\N	["guest"]	pending	\N
user-19-b6e67659@example.com	User 19	hashedpassword	\N	\N	t	2025-08-29 21:59:39.99673+07	2025-08-29 21:59:39.99673+07	b6e67659-ed7d-4cf8-a595-701cefe086d6	\N	["guest"]	pending	\N
user-20-d8f38583@example.com	User 20	hashedpassword	\N	\N	t	2025-08-29 21:59:39.9975+07	2025-08-29 21:59:39.9975+07	d8f38583-e170-4c12-a5cc-99048daaa6a1	\N	["guest"]	pending	\N
user-22-59b3eb04@example.com	User 22	hashedpassword	\N	\N	t	2025-08-29 21:59:39.999154+07	2025-08-29 21:59:39.999154+07	59b3eb04-4796-42b8-a04e-be8a803d0c4d	\N	["guest"]	pending	\N
user-24-9d37b807@example.com	User 24	hashedpassword	\N	\N	t	2025-08-29 21:59:40.001743+07	2025-08-29 21:59:40.001743+07	9d37b807-d54a-4c69-9044-ba4b62ae3460	\N	["guest"]	pending	\N
user-26-c0261e4a@example.com	User 26	hashedpassword	\N	\N	t	2025-08-29 21:59:40.004889+07	2025-08-29 21:59:40.004889+07	c0261e4a-8080-4d34-877c-3238b6801cfa	\N	["guest"]	pending	\N
user-27-52d722d8@example.com	User 27	hashedpassword	\N	\N	t	2025-08-29 21:59:40.005516+07	2025-08-29 21:59:40.005516+07	52d722d8-5cad-4e35-906b-e9a914775120	\N	["guest"]	pending	\N
user-28-5218ffde@example.com	User 28	hashedpassword	\N	\N	t	2025-08-29 21:59:40.007069+07	2025-08-29 21:59:40.00707+07	5218ffde-606c-4852-958c-aae3d36aa93b	\N	["guest"]	pending	\N
user-30-5e78a571@example.com	User 30	hashedpassword	\N	\N	t	2025-08-29 21:59:40.009502+07	2025-08-29 21:59:40.009502+07	5e78a571-ab3f-4286-a545-c3958c5a5d7b	\N	["guest"]	pending	\N
user-32-c9e990d6@example.com	User 32	hashedpassword	\N	\N	t	2025-08-29 21:59:40.011858+07	2025-08-29 21:59:40.011858+07	c9e990d6-2c06-4fe3-a2f6-bad6b17a8974	\N	["guest"]	pending	\N
user-36-216471f9@example.com	User 36	hashedpassword	\N	\N	t	2025-08-29 21:59:40.015006+07	2025-08-29 21:59:40.015006+07	216471f9-1da3-40fa-a544-34fe15640dde	\N	["guest"]	pending	\N
user-40-52887af5@example.com	User 40	hashedpassword	\N	\N	t	2025-08-29 21:59:40.019543+07	2025-08-29 21:59:40.019543+07	52887af5-398d-4e8b-ae67-455945b67c6c	\N	["guest"]	pending	\N
user-46-0dae0122@example.com	User 46	hashedpassword	\N	\N	t	2025-08-29 21:59:40.025165+07	2025-08-29 21:59:40.025165+07	0dae0122-4f32-4840-b107-2873e193b8cc	\N	["guest"]	pending	\N
user-48-7ccf673a@example.com	User 48	hashedpassword	\N	\N	t	2025-08-29 21:59:40.027229+07	2025-08-29 21:59:40.027229+07	7ccf673a-c8b4-4f3e-b375-bdcd8028b12e	\N	["guest"]	pending	\N
user-52-e3cab8e2@example.com	User 52	hashedpassword	\N	\N	t	2025-08-29 21:59:40.030264+07	2025-08-29 21:59:40.030264+07	e3cab8e2-5a94-4949-a891-88567b7ab8fb	\N	["guest"]	pending	\N
user-55-1d73e57e@example.com	User 55	hashedpassword	\N	\N	t	2025-08-29 21:59:40.032719+07	2025-08-29 21:59:40.032719+07	1d73e57e-fe99-4324-90e7-a4572f938655	\N	["guest"]	pending	\N
user-68-7ba4094b@example.com	User 68	hashedpassword	\N	\N	t	2025-08-29 21:59:40.095005+07	2025-08-29 21:59:40.095005+07	7ba4094b-01ff-4665-9ac4-85a7b8ed41e8	\N	["guest"]	pending	\N
user-74-a33ba10b@example.com	User 74	hashedpassword	\N	\N	t	2025-08-29 21:59:40.141181+07	2025-08-29 21:59:40.141181+07	a33ba10b-7eca-4a1e-bcb2-a18db16e36c1	\N	["guest"]	pending	\N
user-77-733c74dc@example.com	User 77	hashedpassword	\N	\N	t	2025-08-29 21:59:40.145591+07	2025-08-29 21:59:40.145591+07	733c74dc-2ebe-4c52-9677-2cc189f7ed86	\N	["guest"]	pending	\N
user-84-3290499e@example.com	User 84	hashedpassword	\N	\N	t	2025-08-29 21:59:40.150484+07	2025-08-29 21:59:40.150484+07	3290499e-71b2-43fb-974c-4cb34216cc40	\N	["guest"]	pending	\N
user-88-680bbad5@example.com	User 88	hashedpassword	\N	\N	t	2025-08-29 21:59:40.152781+07	2025-08-29 21:59:40.152781+07	680bbad5-4033-4d22-8ad3-ece16fa437ba	\N	["guest"]	pending	\N
user-91-04d383dd@example.com	User 91	hashedpassword	\N	\N	t	2025-08-29 21:59:40.154961+07	2025-08-29 21:59:40.154961+07	04d383dd-ece4-446e-a1d5-d6f05637618b	\N	["guest"]	pending	\N
user-94-50ba3f4e@example.com	User 94	hashedpassword	\N	\N	t	2025-08-29 21:59:40.157739+07	2025-08-29 21:59:40.157739+07	50ba3f4e-1936-43de-b83c-150c453ca6ff	\N	["guest"]	pending	\N
user-98-0c1e63f4@example.com	User 98	hashedpassword	\N	\N	t	2025-08-29 21:59:40.162324+07	2025-08-29 21:59:40.162324+07	0c1e63f4-6a18-423a-a961-8f844e687d41	\N	["guest"]	pending	\N
concurrent-user-0-f1ac282d@example.com	Concurrent User 0	password	\N	\N	t	2025-08-29 21:59:40.598821+07	2025-08-29 21:59:40.598821+07	f1ac282d-e146-4a9c-a75f-d0f805d783b2	\N	["guest"]	pending	\N
concurrent-user-4-4df286e3@example.com	Concurrent User 4	password	\N	\N	t	2025-08-29 21:59:40.598797+07	2025-08-29 21:59:40.598797+07	4df286e3-240d-41d3-ab0b-302b54cc7b1b	\N	["guest"]	pending	\N
perf-test-0-89216366@example.com	Performance User 0	password	\N	\N	t	2025-08-29 21:59:40.811326+07	2025-08-29 21:59:40.811326+07	89216366-6c26-4d7f-9dfc-b852df65d082	\N	["guest"]	pending	\N
perf-test-1-a4538567@example.com	Performance User 1	password	\N	\N	t	2025-08-29 21:59:40.813502+07	2025-08-29 21:59:40.813502+07	a4538567-47c8-4fd5-a831-2498f632f933	\N	["guest"]	pending	\N
perf-test-2-8a452767@example.com	Performance User 2	password	\N	\N	t	2025-08-29 21:59:40.81469+07	2025-08-29 21:59:40.81469+07	8a452767-6399-4d85-9edf-e27212db3b2d	\N	["guest"]	pending	\N
perf-test-3-6a38a70a@example.com	Performance User 3	password	\N	\N	t	2025-08-29 21:59:40.815571+07	2025-08-29 21:59:40.815571+07	6a38a70a-3550-43f9-b280-4d22f3db0538	\N	["guest"]	pending	\N
perf-test-4-c0523f71@example.com	Performance User 4	password	\N	\N	t	2025-08-29 21:59:40.817345+07	2025-08-29 21:59:40.817345+07	c0523f71-ed63-4392-a024-a9c3cbb4e2a4	\N	["guest"]	pending	\N
perf-test-5-2423a9aa@example.com	Performance User 5	password	\N	\N	t	2025-08-29 21:59:40.818744+07	2025-08-29 21:59:40.818744+07	2423a9aa-90ca-4f10-a59f-2c2b102f9764	\N	["guest"]	pending	\N
perf-test-6-4f391f2f@example.com	Performance User 6	password	\N	\N	t	2025-08-29 21:59:40.822926+07	2025-08-29 21:59:40.822926+07	4f391f2f-e0b7-4787-ad0a-83c02f96ba49	\N	["guest"]	pending	\N
perf-test-7-4f2175b4@example.com	Performance User 7	password	\N	\N	t	2025-08-29 21:59:40.82418+07	2025-08-29 21:59:40.824181+07	4f2175b4-ea68-45c6-a9c2-49e93b00de41	\N	["guest"]	pending	\N
perf-test-8-c25c1659@example.com	Performance User 8	password	\N	\N	t	2025-08-29 21:59:40.825268+07	2025-08-29 21:59:40.825268+07	c25c1659-199b-40ff-accd-943d8a4de04d	\N	["guest"]	pending	\N
perf-test-9-72190233@example.com	Performance User 9	password	\N	\N	t	2025-08-29 21:59:40.826682+07	2025-08-29 21:59:40.826682+07	72190233-f592-4488-8efa-221ba2a6eb9f	\N	["guest"]	pending	\N
perf-test-10-690fb0b5@example.com	Performance User 10	password	\N	\N	t	2025-08-29 21:59:40.828044+07	2025-08-29 21:59:40.828044+07	690fb0b5-8664-4231-aa85-0eb94d21e3c4	\N	["guest"]	pending	\N
perf-test-11-fb0eec6a@example.com	Performance User 11	password	\N	\N	t	2025-08-29 21:59:40.828968+07	2025-08-29 21:59:40.828969+07	fb0eec6a-3dc5-4bba-b531-91b5630267d1	\N	["guest"]	pending	\N
perf-test-12-062602b3@example.com	Performance User 12	password	\N	\N	t	2025-08-29 21:59:40.830168+07	2025-08-29 21:59:40.830168+07	062602b3-5689-4bab-a412-7491f3a02676	\N	["guest"]	pending	\N
perf-test-13-c11de032@example.com	Performance User 13	password	\N	\N	t	2025-08-29 21:59:40.831127+07	2025-08-29 21:59:40.831127+07	c11de032-fec0-4b7a-8881-bf8d33470296	\N	["guest"]	pending	\N
perf-test-14-9cae5b8e@example.com	Performance User 14	password	\N	\N	t	2025-08-29 21:59:40.831929+07	2025-08-29 21:59:40.831929+07	9cae5b8e-8e02-4683-8a63-6feefa7f4a53	\N	["guest"]	pending	\N
perf-test-15-6f463e5b@example.com	Performance User 15	password	\N	\N	t	2025-08-29 21:59:40.833393+07	2025-08-29 21:59:40.833393+07	6f463e5b-c097-4a3c-8c92-2df3da5f7e75	\N	["guest"]	pending	\N
perf-test-16-fd62d2aa@example.com	Performance User 16	password	\N	\N	t	2025-08-29 21:59:40.834539+07	2025-08-29 21:59:40.834539+07	fd62d2aa-0e7c-43c8-be4f-7506fecbca3e	\N	["guest"]	pending	\N
perf-test-17-74a35c0a@example.com	Performance User 17	password	\N	\N	t	2025-08-29 21:59:40.838553+07	2025-08-29 21:59:40.838553+07	74a35c0a-15da-49ae-8152-e3727e7187e9	\N	["guest"]	pending	\N
perf-test-18-4d0bcf39@example.com	Performance User 18	password	\N	\N	t	2025-08-29 21:59:40.839338+07	2025-08-29 21:59:40.839338+07	4d0bcf39-9c23-405b-bc1b-5c07828da98c	\N	["guest"]	pending	\N
perf-test-19-fdfebd7c@example.com	Performance User 19	password	\N	\N	t	2025-08-29 21:59:40.840405+07	2025-08-29 21:59:40.840405+07	fdfebd7c-8ca0-4794-bafe-a627967b6072	\N	["guest"]	pending	\N
perf-test-20-6b30e900@example.com	Performance User 20	password	\N	\N	t	2025-08-29 21:59:40.841714+07	2025-08-29 21:59:40.841715+07	6b30e900-1032-4b7c-8f4f-55264dbc7bb0	\N	["guest"]	pending	\N
perf-test-21-0ea559f7@example.com	Performance User 21	password	\N	\N	t	2025-08-29 21:59:40.842954+07	2025-08-29 21:59:40.842954+07	0ea559f7-42c0-4754-b761-fed493d8414f	\N	["guest"]	pending	\N
perf-test-22-4ff6bd72@example.com	Performance User 22	password	\N	\N	t	2025-08-29 21:59:40.844223+07	2025-08-29 21:59:40.844223+07	4ff6bd72-e1e5-41c8-8c66-51bcf65128cc	\N	["guest"]	pending	\N
perf-test-23-20940b61@example.com	Performance User 23	password	\N	\N	t	2025-08-29 21:59:40.84518+07	2025-08-29 21:59:40.84518+07	20940b61-2e85-4d64-b62f-8844df95dc1e	\N	["guest"]	pending	\N
perf-test-24-ee5ba1a8@example.com	Performance User 24	password	\N	\N	t	2025-08-29 21:59:40.846633+07	2025-08-29 21:59:40.846633+07	ee5ba1a8-d201-420c-b303-ab0414934680	\N	["guest"]	pending	\N
perf-test-25-3e250434@example.com	Performance User 25	password	\N	\N	t	2025-08-29 21:59:40.847328+07	2025-08-29 21:59:40.847328+07	3e250434-b59e-47a3-912e-e5517f6b0772	\N	["guest"]	pending	\N
perf-test-26-26d96617@example.com	Performance User 26	password	\N	\N	t	2025-08-29 21:59:40.848563+07	2025-08-29 21:59:40.848563+07	26d96617-663a-40ea-9de1-37f9f81cd746	\N	["guest"]	pending	\N
perf-test-27-3175f92f@example.com	Performance User 27	password	\N	\N	t	2025-08-29 21:59:40.850253+07	2025-08-29 21:59:40.850253+07	3175f92f-7382-42b4-8823-de0eaf9cd0fb	\N	["guest"]	pending	\N
perf-test-28-89df5e11@example.com	Performance User 28	password	\N	\N	t	2025-08-29 21:59:40.851553+07	2025-08-29 21:59:40.851553+07	89df5e11-3864-4d42-a659-be682ce23a2a	\N	["guest"]	pending	\N
perf-test-29-8822a853@example.com	Performance User 29	password	\N	\N	t	2025-08-29 21:59:40.857311+07	2025-08-29 21:59:40.857311+07	8822a853-e210-4fd9-877f-6232490350a7	\N	["guest"]	pending	\N
perf-test-30-f1938609@example.com	Performance User 30	password	\N	\N	t	2025-08-29 21:59:40.858744+07	2025-08-29 21:59:40.858745+07	f1938609-2864-4967-b183-f11e6339a208	\N	["guest"]	pending	\N
perf-test-31-8b22f1d6@example.com	Performance User 31	password	\N	\N	t	2025-08-29 21:59:40.86029+07	2025-08-29 21:59:40.860291+07	8b22f1d6-fb86-4fe0-93bb-57c047b86455	\N	["guest"]	pending	\N
perf-test-32-79861742@example.com	Performance User 32	password	\N	\N	t	2025-08-29 21:59:40.862152+07	2025-08-29 21:59:40.862152+07	79861742-591a-4ce7-9801-e82b04b45fab	\N	["guest"]	pending	\N
perf-test-33-9af0771e@example.com	Performance User 33	password	\N	\N	t	2025-08-29 21:59:40.863193+07	2025-08-29 21:59:40.863193+07	9af0771e-2597-4d63-84f5-7db765aebcbc	\N	["guest"]	pending	\N
perf-test-34-f0e24d76@example.com	Performance User 34	password	\N	\N	t	2025-08-29 21:59:40.864114+07	2025-08-29 21:59:40.864114+07	f0e24d76-1c77-4a08-875e-e0b0e9b779bb	\N	["guest"]	pending	\N
perf-test-35-21295352@example.com	Performance User 35	password	\N	\N	t	2025-08-29 21:59:40.864804+07	2025-08-29 21:59:40.864805+07	21295352-fd96-499b-bbdd-d65d742c7609	\N	["guest"]	pending	\N
perf-test-36-5a9e6f6a@example.com	Performance User 36	password	\N	\N	t	2025-08-29 21:59:40.86673+07	2025-08-29 21:59:40.866731+07	5a9e6f6a-9f0a-48fc-b0c9-3b1386c259ac	\N	["guest"]	pending	\N
perf-test-37-8ea11bb2@example.com	Performance User 37	password	\N	\N	t	2025-08-29 21:59:40.912873+07	2025-08-29 21:59:40.912874+07	8ea11bb2-371b-4603-b95a-a1029bdb15fd	\N	["guest"]	pending	\N
perf-test-38-0019110b@example.com	Performance User 38	password	\N	\N	t	2025-08-29 21:59:40.915096+07	2025-08-29 21:59:40.915096+07	0019110b-a77c-4121-a1d9-4b0f2de3a8f6	\N	["guest"]	pending	\N
perf-test-39-5f489b60@example.com	Performance User 39	password	\N	\N	t	2025-08-29 21:59:40.916895+07	2025-08-29 21:59:40.916895+07	5f489b60-5c1e-4eae-a023-141cee370364	\N	["guest"]	pending	\N
perf-test-40-b6cf6d38@example.com	Performance User 40	password	\N	\N	t	2025-08-29 21:59:40.917653+07	2025-08-29 21:59:40.917653+07	b6cf6d38-8319-496c-bf55-de4609f7ef11	\N	["guest"]	pending	\N
perf-test-41-0428fb9e@example.com	Performance User 41	password	\N	\N	t	2025-08-29 21:59:40.918517+07	2025-08-29 21:59:40.918517+07	0428fb9e-31fd-421f-8ea1-5b311a0ecdc5	\N	["guest"]	pending	\N
perf-test-42-0913fc21@example.com	Performance User 42	password	\N	\N	t	2025-08-29 21:59:40.927409+07	2025-08-29 21:59:40.927409+07	0913fc21-f6bc-46bd-8bb7-27fbf040b3da	\N	["guest"]	pending	\N
perf-test-43-eae27639@example.com	Performance User 43	password	\N	\N	t	2025-08-29 21:59:40.960823+07	2025-08-29 21:59:40.960823+07	eae27639-d6bc-4d47-ba48-5fbb6efdaf2b	\N	["guest"]	pending	\N
perf-test-44-ed86d750@example.com	Performance User 44	password	\N	\N	t	2025-08-29 21:59:41.057073+07	2025-08-29 21:59:41.057073+07	ed86d750-0299-4fff-9c16-7c402fc01187	\N	["guest"]	pending	\N
perf-test-45-6c78239a@example.com	Performance User 45	password	\N	\N	t	2025-08-29 21:59:41.098416+07	2025-08-29 21:59:41.098416+07	6c78239a-57ea-404e-a8f1-01e02eb60042	\N	["guest"]	pending	\N
perf-test-46-ff075a16@example.com	Performance User 46	password	\N	\N	t	2025-08-29 21:59:41.140209+07	2025-08-29 21:59:41.140209+07	ff075a16-7f0f-454c-9bb7-063beab7248a	\N	["guest"]	pending	\N
perf-test-47-f6a696ba@example.com	Performance User 47	password	\N	\N	t	2025-08-29 21:59:41.182632+07	2025-08-29 21:59:41.182632+07	f6a696ba-f554-4cb0-a929-d6eec584b24d	\N	["guest"]	pending	\N
perf-test-48-55be79fa@example.com	Performance User 48	password	\N	\N	t	2025-08-29 21:59:41.223425+07	2025-08-29 21:59:41.223426+07	55be79fa-e9fb-4788-ac5c-2dade1fb516a	\N	["guest"]	pending	\N
perf-test-49-cbe619c5@example.com	Performance User 49	password	\N	\N	t	2025-08-29 21:59:41.225619+07	2025-08-29 21:59:41.225619+07	cbe619c5-bc89-4b3d-8da8-fe334f4d6346	\N	["guest"]	pending	\N
user-1-ed727285@example.com	User 1	hashedpassword	\N	\N	t	2025-08-29 22:02:00.801181+07	2025-08-29 22:02:00.801181+07	ed727285-085a-43cf-aff2-77ddbe59621c	\N	["guest"]	pending	\N
user-3-1cf0ac70@example.com	User 3	hashedpassword	\N	\N	t	2025-08-29 22:02:00.849563+07	2025-08-29 22:02:00.849563+07	1cf0ac70-ad83-4847-93b2-c740f54ed0aa	\N	["guest"]	pending	\N
user-7-656ca945@example.com	User 7	hashedpassword	\N	\N	t	2025-08-29 22:02:00.85525+07	2025-08-29 22:02:00.85525+07	656ca945-7b93-48d3-87bf-e368ac9f8b71	\N	["guest"]	pending	\N
user-16-8d011d88@example.com	User 16	hashedpassword	\N	\N	t	2025-08-29 22:02:00.861551+07	2025-08-29 22:02:00.861551+07	8d011d88-8074-48fc-8747-b01010a1ab17	\N	["guest"]	pending	\N
user-17-5622aa8b@example.com	User 17	hashedpassword	\N	\N	t	2025-08-29 22:02:00.862029+07	2025-08-29 22:02:00.862029+07	5622aa8b-0ec5-429d-a8cb-b0d87ce2cd15	\N	["guest"]	pending	\N
user-18-1f6006d3@example.com	User 18	hashedpassword	\N	\N	t	2025-08-29 22:02:00.862444+07	2025-08-29 22:02:00.862444+07	1f6006d3-7f9d-40e6-8064-5a0312abcd09	\N	["guest"]	pending	\N
user-24-89887b8c@example.com	User 24	hashedpassword	\N	\N	t	2025-08-29 22:02:00.866079+07	2025-08-29 22:02:00.86608+07	89887b8c-ff4a-4db6-ab8f-52753d4a5ce4	\N	["guest"]	pending	\N
user-32-bf44451c@example.com	User 32	hashedpassword	\N	\N	t	2025-08-29 22:02:00.869469+07	2025-08-29 22:02:00.869469+07	bf44451c-daeb-48f4-a56a-7a8cade58cc0	\N	["guest"]	pending	\N
user-33-aaa177c3@example.com	User 33	hashedpassword	\N	\N	t	2025-08-29 22:02:00.869887+07	2025-08-29 22:02:00.869887+07	aaa177c3-51d5-4e9e-91cb-aa7e8c88a2e9	\N	["guest"]	pending	\N
user-37-bce7ca3e@example.com	User 37	hashedpassword	\N	\N	t	2025-08-29 22:02:00.872242+07	2025-08-29 22:02:00.872243+07	bce7ca3e-0fc0-482d-bc30-c354261b470c	\N	["guest"]	pending	\N
user-41-7dc442ce@example.com	User 41	hashedpassword	\N	\N	t	2025-08-29 22:02:00.874412+07	2025-08-29 22:02:00.874412+07	7dc442ce-b6c6-47ed-bfdf-bdafdb9400f8	\N	["guest"]	pending	\N
user-45-28bf4eef@example.com	User 45	hashedpassword	\N	\N	t	2025-08-29 22:02:00.87618+07	2025-08-29 22:02:00.87618+07	28bf4eef-f950-4208-b574-36f86992b3a0	\N	["guest"]	pending	\N
user-53-452fc4a9@example.com	User 53	hashedpassword	\N	\N	t	2025-08-29 22:02:00.879461+07	2025-08-29 22:02:00.879461+07	452fc4a9-993c-4573-a806-fc17a901df5e	\N	["guest"]	pending	\N
user-60-2497b8b5@example.com	User 60	hashedpassword	\N	\N	t	2025-08-29 22:02:00.883616+07	2025-08-29 22:02:00.883616+07	2497b8b5-9500-44b6-a9bb-37c2e14f860a	\N	["guest"]	pending	\N
user-66-ed4d2ac0@example.com	User 66	hashedpassword	\N	\N	t	2025-08-29 22:02:00.885948+07	2025-08-29 22:02:00.885948+07	ed4d2ac0-5736-4b20-b096-e39dfca568b9	\N	["guest"]	pending	\N
user-68-bb708dd9@example.com	User 68	hashedpassword	\N	\N	t	2025-08-29 22:02:00.886673+07	2025-08-29 22:02:00.886673+07	bb708dd9-f8f1-4d8b-a0e8-939d94161f6f	\N	["guest"]	pending	\N
user-76-b9c37303@example.com	User 76	hashedpassword	\N	\N	t	2025-08-29 22:02:00.890523+07	2025-08-29 22:02:00.890523+07	b9c37303-6731-4724-8008-f69c9ce04c49	\N	["guest"]	pending	\N
user-81-69069e6d@example.com	User 81	hashedpassword	\N	\N	t	2025-08-29 22:02:00.892743+07	2025-08-29 22:02:00.892743+07	69069e6d-a5dc-4d94-bf73-655d0fa171ad	\N	["guest"]	pending	\N
user-82-5d0b49f9@example.com	User 82	hashedpassword	\N	\N	t	2025-08-29 22:02:00.893126+07	2025-08-29 22:02:00.893126+07	5d0b49f9-b286-4cd6-ac31-5f1efa20c4b2	\N	["guest"]	pending	\N
user-86-2d4a0c88@example.com	User 86	hashedpassword	\N	\N	t	2025-08-29 22:02:00.894739+07	2025-08-29 22:02:00.894739+07	2d4a0c88-8c02-47f5-aa89-13987cc6b435	\N	["guest"]	pending	\N
user-88-8848dafc@example.com	User 88	hashedpassword	\N	\N	t	2025-08-29 22:02:00.895532+07	2025-08-29 22:02:00.895532+07	8848dafc-ab53-43da-8676-27fb32408afb	\N	["guest"]	pending	\N
user-92-29aa6f8c@example.com	User 92	hashedpassword	\N	\N	t	2025-08-29 22:02:00.897617+07	2025-08-29 22:02:00.897617+07	29aa6f8c-ab65-4cfe-9244-1da9804666c4	\N	["guest"]	pending	\N
user-93-ba523ca6@example.com	User 93	hashedpassword	\N	\N	t	2025-08-29 22:02:00.898286+07	2025-08-29 22:02:00.898287+07	ba523ca6-3e04-4ff1-9521-eb5416652a48	\N	["guest"]	pending	\N
user-97-db3c9eff@example.com	User 97	hashedpassword	\N	\N	t	2025-08-29 22:02:00.900487+07	2025-08-29 22:02:00.900487+07	db3c9eff-b186-4de7-bf95-5eeebc2d7488	\N	["guest"]	pending	\N
concurrent-user-0-54a2575f@example.com	Concurrent User 0	password	\N	\N	t	2025-08-29 22:02:01.174409+07	2025-08-29 22:02:01.174409+07	54a2575f-b2bf-4a6d-a2fa-6646618da01a	\N	["guest"]	pending	\N
concurrent-user-4-1871eaf5@example.com	Concurrent User 4	password	\N	\N	t	2025-08-29 22:02:01.174271+07	2025-08-29 22:02:01.174272+07	1871eaf5-286d-464b-a3cb-59f7fec49c19	\N	["guest"]	pending	\N
perf-test-0-3ecf2355@example.com	Performance User 0	password	\N	\N	t	2025-08-29 22:02:01.316857+07	2025-08-29 22:02:01.316858+07	3ecf2355-369b-4dd1-991b-43710cab9259	\N	["guest"]	pending	\N
perf-test-1-a9fcdbb0@example.com	Performance User 1	password	\N	\N	t	2025-08-29 22:02:01.318615+07	2025-08-29 22:02:01.318615+07	a9fcdbb0-fad9-4e91-9aa8-629d572f6ea4	\N	["guest"]	pending	\N
perf-test-2-450e05f9@example.com	Performance User 2	password	\N	\N	t	2025-08-29 22:02:01.319151+07	2025-08-29 22:02:01.319151+07	450e05f9-d16b-453b-93a5-38d8aeebb1d1	\N	["guest"]	pending	\N
perf-test-3-3c9e9859@example.com	Performance User 3	password	\N	\N	t	2025-08-29 22:02:01.319593+07	2025-08-29 22:02:01.319593+07	3c9e9859-58bf-484e-a15c-39120bd3d53b	\N	["guest"]	pending	\N
perf-test-4-d08999ff@example.com	Performance User 4	password	\N	\N	t	2025-08-29 22:02:01.320039+07	2025-08-29 22:02:01.320039+07	d08999ff-0814-4106-8ae6-5d1901998217	\N	["guest"]	pending	\N
perf-test-5-a6cece5a@example.com	Performance User 5	password	\N	\N	t	2025-08-29 22:02:01.320546+07	2025-08-29 22:02:01.320546+07	a6cece5a-fa08-40d3-b0f1-72096868d5ce	\N	["guest"]	pending	\N
perf-test-6-35f3811d@example.com	Performance User 6	password	\N	\N	t	2025-08-29 22:02:01.321036+07	2025-08-29 22:02:01.321036+07	35f3811d-151b-4b36-a2e8-e462a4fb2ea7	\N	["guest"]	pending	\N
perf-test-7-85f5115d@example.com	Performance User 7	password	\N	\N	t	2025-08-29 22:02:01.321631+07	2025-08-29 22:02:01.321631+07	85f5115d-7af7-46c4-bfc1-0f4ea06f3916	\N	["guest"]	pending	\N
perf-test-8-31480937@example.com	Performance User 8	password	\N	\N	t	2025-08-29 22:02:01.322182+07	2025-08-29 22:02:01.322182+07	31480937-020a-4ac3-b052-87846fcf6a08	\N	["guest"]	pending	\N
perf-test-9-b4c171be@example.com	Performance User 9	password	\N	\N	t	2025-08-29 22:02:01.322869+07	2025-08-29 22:02:01.32287+07	b4c171be-d96f-457d-9bd3-d9eb1e77ed59	\N	["guest"]	pending	\N
perf-test-10-a9bdb3d7@example.com	Performance User 10	password	\N	\N	t	2025-08-29 22:02:01.323506+07	2025-08-29 22:02:01.323507+07	a9bdb3d7-2b81-420e-914d-84a72479cd11	\N	["guest"]	pending	\N
perf-test-11-c7b85417@example.com	Performance User 11	password	\N	\N	t	2025-08-29 22:02:01.324132+07	2025-08-29 22:02:01.324132+07	c7b85417-d8ef-46dc-a28c-6bc4d2cf14ff	\N	["guest"]	pending	\N
perf-test-12-16ddbc7b@example.com	Performance User 12	password	\N	\N	t	2025-08-29 22:02:01.324935+07	2025-08-29 22:02:01.324935+07	16ddbc7b-77d5-4925-beff-fa607406a732	\N	["guest"]	pending	\N
perf-test-13-9c7495cf@example.com	Performance User 13	password	\N	\N	t	2025-08-29 22:02:01.325418+07	2025-08-29 22:02:01.325418+07	9c7495cf-4303-43a1-a567-3f7a22f52a94	\N	["guest"]	pending	\N
perf-test-14-d9817bed@example.com	Performance User 14	password	\N	\N	t	2025-08-29 22:02:01.325962+07	2025-08-29 22:02:01.325962+07	d9817bed-c160-4128-8316-07071faf6164	\N	["guest"]	pending	\N
perf-test-15-126f56d8@example.com	Performance User 15	password	\N	\N	t	2025-08-29 22:02:01.326434+07	2025-08-29 22:02:01.326434+07	126f56d8-3ddb-4fe4-8f51-1df2d608971c	\N	["guest"]	pending	\N
perf-test-16-f4d0dbb9@example.com	Performance User 16	password	\N	\N	t	2025-08-29 22:02:01.326876+07	2025-08-29 22:02:01.326876+07	f4d0dbb9-9e1c-4d7d-bb3c-7e6fa71220ed	\N	["guest"]	pending	\N
perf-test-17-9205fd1b@example.com	Performance User 17	password	\N	\N	t	2025-08-29 22:02:01.327298+07	2025-08-29 22:02:01.327298+07	9205fd1b-4c40-4f3b-aaa3-36661cb1fc4c	\N	["guest"]	pending	\N
perf-test-18-6a21ebc5@example.com	Performance User 18	password	\N	\N	t	2025-08-29 22:02:01.327718+07	2025-08-29 22:02:01.327718+07	6a21ebc5-d649-4190-84e4-858c3a37a064	\N	["guest"]	pending	\N
perf-test-19-29d1642b@example.com	Performance User 19	password	\N	\N	t	2025-08-29 22:02:01.328077+07	2025-08-29 22:02:01.328077+07	29d1642b-4c6f-453e-a900-3a745c2fb9c0	\N	["guest"]	pending	\N
perf-test-20-9ae9e6ea@example.com	Performance User 20	password	\N	\N	t	2025-08-29 22:02:01.328439+07	2025-08-29 22:02:01.328439+07	9ae9e6ea-cc19-42f1-b094-ce755ec056c3	\N	["guest"]	pending	\N
perf-test-21-ef227c28@example.com	Performance User 21	password	\N	\N	t	2025-08-29 22:02:01.328918+07	2025-08-29 22:02:01.328918+07	ef227c28-c124-46cb-8821-dd0d9064307d	\N	["guest"]	pending	\N
perf-test-22-9e1ae205@example.com	Performance User 22	password	\N	\N	t	2025-08-29 22:02:01.329413+07	2025-08-29 22:02:01.329413+07	9e1ae205-564e-407c-a841-a0fa77707f70	\N	["guest"]	pending	\N
perf-test-23-664e70a1@example.com	Performance User 23	password	\N	\N	t	2025-08-29 22:02:01.329934+07	2025-08-29 22:02:01.329934+07	664e70a1-f4ab-40c7-a7f3-d8a003b858a6	\N	["guest"]	pending	\N
perf-test-24-a41c5bd1@example.com	Performance User 24	password	\N	\N	t	2025-08-29 22:02:01.330428+07	2025-08-29 22:02:01.330429+07	a41c5bd1-a504-4e20-a423-dd7ab2f42ff0	\N	["guest"]	pending	\N
perf-test-25-78ec4480@example.com	Performance User 25	password	\N	\N	t	2025-08-29 22:02:01.331091+07	2025-08-29 22:02:01.331092+07	78ec4480-bb71-482f-8513-b196245a8b14	\N	["guest"]	pending	\N
perf-test-26-887b68e5@example.com	Performance User 26	password	\N	\N	t	2025-08-29 22:02:01.331794+07	2025-08-29 22:02:01.331794+07	887b68e5-ee3f-46a2-9099-fd9b1d8e9a4f	\N	["guest"]	pending	\N
perf-test-27-9afb7795@example.com	Performance User 27	password	\N	\N	t	2025-08-29 22:02:01.332398+07	2025-08-29 22:02:01.332398+07	9afb7795-4a47-4112-9d77-6afef24e9411	\N	["guest"]	pending	\N
perf-test-28-b9cbb121@example.com	Performance User 28	password	\N	\N	t	2025-08-29 22:02:01.33297+07	2025-08-29 22:02:01.33297+07	b9cbb121-d10e-4cfc-aec8-1eda12fbe26e	\N	["guest"]	pending	\N
perf-test-29-54bf4f6c@example.com	Performance User 29	password	\N	\N	t	2025-08-29 22:02:01.333451+07	2025-08-29 22:02:01.333452+07	54bf4f6c-a4e2-43ea-ae07-5ab655409318	\N	["guest"]	pending	\N
perf-test-30-b69e66bb@example.com	Performance User 30	password	\N	\N	t	2025-08-29 22:02:01.333978+07	2025-08-29 22:02:01.333978+07	b69e66bb-35c3-49e8-87f2-09bb4e2e12ab	\N	["guest"]	pending	\N
perf-test-31-bdf7b86b@example.com	Performance User 31	password	\N	\N	t	2025-08-29 22:02:01.334455+07	2025-08-29 22:02:01.334455+07	bdf7b86b-a20a-4892-af21-e39c13003cc2	\N	["guest"]	pending	\N
perf-test-32-835251c7@example.com	Performance User 32	password	\N	\N	t	2025-08-29 22:02:01.334805+07	2025-08-29 22:02:01.334805+07	835251c7-35cb-4abc-91d0-af58941b487a	\N	["guest"]	pending	\N
perf-test-33-f240a92c@example.com	Performance User 33	password	\N	\N	t	2025-08-29 22:02:01.33518+07	2025-08-29 22:02:01.33518+07	f240a92c-367d-48af-a072-5e6abb5e062c	\N	["guest"]	pending	\N
perf-test-34-80c43931@example.com	Performance User 34	password	\N	\N	t	2025-08-29 22:02:01.33552+07	2025-08-29 22:02:01.33552+07	80c43931-5e47-4d07-9eaa-ab9b826db99f	\N	["guest"]	pending	\N
perf-test-35-a22fd0fb@example.com	Performance User 35	password	\N	\N	t	2025-08-29 22:02:01.3359+07	2025-08-29 22:02:01.3359+07	a22fd0fb-df1e-4ac2-884d-1046a9e3c3a0	\N	["guest"]	pending	\N
perf-test-36-3eea2dd7@example.com	Performance User 36	password	\N	\N	t	2025-08-29 22:02:01.336233+07	2025-08-29 22:02:01.336233+07	3eea2dd7-81b4-48b1-9bcf-0a2f3cc5416b	\N	["guest"]	pending	\N
perf-test-37-527f1fa8@example.com	Performance User 37	password	\N	\N	t	2025-08-29 22:02:01.336596+07	2025-08-29 22:02:01.336596+07	527f1fa8-5007-4a8d-a8c3-6b1e6ee991b7	\N	["guest"]	pending	\N
perf-test-38-8b6bfc50@example.com	Performance User 38	password	\N	\N	t	2025-08-29 22:02:01.336941+07	2025-08-29 22:02:01.336941+07	8b6bfc50-f1ab-4c94-ad1f-4599605264b0	\N	["guest"]	pending	\N
perf-test-39-7db1ef3e@example.com	Performance User 39	password	\N	\N	t	2025-08-29 22:02:01.337496+07	2025-08-29 22:02:01.337496+07	7db1ef3e-f78f-40cd-834d-e4cecc5cc6a0	\N	["guest"]	pending	\N
perf-test-40-8e0186d1@example.com	Performance User 40	password	\N	\N	t	2025-08-29 22:02:01.337917+07	2025-08-29 22:02:01.337917+07	8e0186d1-e157-4061-bcbe-0d420f69edcb	\N	["guest"]	pending	\N
perf-test-41-0d31fda3@example.com	Performance User 41	password	\N	\N	t	2025-08-29 22:02:01.33835+07	2025-08-29 22:02:01.33835+07	0d31fda3-8e95-43bc-9f26-939c127ab85d	\N	["guest"]	pending	\N
perf-test-42-907c608f@example.com	Performance User 42	password	\N	\N	t	2025-08-29 22:02:01.338938+07	2025-08-29 22:02:01.338938+07	907c608f-d42d-4f04-9512-a7a20a68ce7b	\N	["guest"]	pending	\N
perf-test-43-c12549ec@example.com	Performance User 43	password	\N	\N	t	2025-08-29 22:02:01.339453+07	2025-08-29 22:02:01.339453+07	c12549ec-646a-4af1-8499-0ceb10212ffd	\N	["guest"]	pending	\N
perf-test-44-c9b40f6c@example.com	Performance User 44	password	\N	\N	t	2025-08-29 22:02:01.339969+07	2025-08-29 22:02:01.339969+07	c9b40f6c-d776-42fc-8211-bb09aaec9983	\N	["guest"]	pending	\N
perf-test-45-dccc72b7@example.com	Performance User 45	password	\N	\N	t	2025-08-29 22:02:01.34048+07	2025-08-29 22:02:01.34048+07	dccc72b7-78ff-4100-975d-5f0e7d714921	\N	["guest"]	pending	\N
perf-test-46-884c100d@example.com	Performance User 46	password	\N	\N	t	2025-08-29 22:02:01.341019+07	2025-08-29 22:02:01.341019+07	884c100d-19fe-4251-8064-7b903b49ec74	\N	["guest"]	pending	\N
perf-test-47-b04922a6@example.com	Performance User 47	password	\N	\N	t	2025-08-29 22:02:01.341824+07	2025-08-29 22:02:01.341824+07	b04922a6-655d-467c-81b7-825eab6fb6fe	\N	["guest"]	pending	\N
perf-test-48-0f13de67@example.com	Performance User 48	password	\N	\N	t	2025-08-29 22:02:01.342344+07	2025-08-29 22:02:01.342344+07	0f13de67-cd18-4e6e-9e46-c63795043903	\N	["guest"]	pending	\N
perf-test-49-aa161218@example.com	Performance User 49	password	\N	\N	t	2025-08-29 22:02:01.342757+07	2025-08-29 22:02:01.342757+07	aa161218-efcd-4f1d-ab20-40fe8c6707ad	\N	["guest"]	pending	\N
test@example.com	Test User	$2a$10$WX/LmX3tD1D50ghPT.Hmc.RxzeRizFVse9JtZXW0O4V0bCOnTVNY2	+1234567890	Test Address	t	2025-08-30 01:19:11.710144+07	2025-08-30 01:19:11.710144+07	1e6aebb1-58e3-4a49-bbe8-773d017dcca9	\N	["member"]	pending	\N
testuser1756491723059@example.com	Test User	$2a$10$W3ieTjCzht7DJBBnJx/13./OltiS5NVkL7.8pt3eAiX4VlXzxfUOO	+1234567890	Test Address	t	2025-08-30 01:22:03.157185+07	2025-08-30 01:22:03.157185+07	e61a9e29-270e-4002-9b0b-34a300279bfe	\N	["member"]	pending	\N
testuser1756491760002@example.com	Test User	$2a$10$jwnHoKMIC/ZWVoRZIJeBYufeRyhs0LRZeIAqSyA5wsvLLH0gptose	+1234567890	Test Address	t	2025-08-30 01:22:40.34554+07	2025-08-30 01:22:40.34554+07	65ac7063-5a2e-44e3-a4b1-91d77ed0bb66	\N	["member"]	pending	\N
investor@comfunds.com	Test Investor	$2a$10$zyW92Et/DM.BeqLIRFoLlOUFQDORp4IvoO8yZ2.BkIzCKOsEWWA3q	+62-822-22222222	Jl. Investor No. 2, Jakarta	t	2025-08-31 12:13:21.907508+07	2025-08-31 12:13:21.907508+07	c8184a46-4f13-44ec-858d-54317f086755	\N	["investor"]	pending	\N
testuser1@sidana.coop	Test User 1	$2a$10$dQFXbUM4UzWtZvc6LlPk3u63UpGmB7uF7xMiY5IsECRkhM1dhir22	+62-811-11111111	Jl. Test No. 1, Bandung	t	2025-08-31 12:17:20.049119+07	2025-08-31 12:17:20.049119+07	7ffcb079-e284-4ef8-81d9-cfb62be820b8	\N	["member"]	pending	\N
newuser@example.com	New Test User	$2a$10$iC9L034gsw.SCgR9DXlWzeymWRFcCPsh4/V65ATUI85XMhM948qUe	+1234567891	456 Test Avenue	t	2025-09-06 00:01:38.460481+07	2025-09-06 00:01:38.460481+07	0e66fc43-1e52-4797-89e2-62b4cd54ea78	\N	["guest"]	pending	\N
testuser1757092347183@example.com	Test User	$2a$10$doXsm0ohkjRHex2ImGDik.EgQh49VCjCcqDs0rbupPf1LY3NfYSUa	+1234567890	Test Address	t	2025-09-06 00:12:27.310563+07	2025-09-06 00:12:27.310563+07	299984e8-39bb-4847-b265-89acd58a8d70	\N	["member"]	pending	\N
testuser@example.com	Test User	$2a$10$wNU6JQkn4c34HpuQo4mZ4ei7RuDzPZnfDPDALIoP.nkOkAeDgYBni	+62-812-1111-2222	Jl. Test No. 123, Jakarta	t	2025-09-19 21:28:21.698622+07	2025-09-19 21:28:21.698622+07	5c16305d-a4dd-4cd3-9e71-aac2036491eb	550e8400-e29b-41d4-a716-446655440001	["investor"]	pending	\N
debug-test@example.com	Debug Test User	$2a$10$8/vdKw3PZdRTOxotWNP9j.auPh8ZxxumTY.Xzey/pg.PhIgaOxsua	+62-816-5555-6666	Jl. Debug Test No. 456, Jakarta	t	2025-09-19 22:00:14.612969+07	2025-09-19 22:00:14.612969+07	aabb90a0-7362-44d4-9cea-c25bf2ff6cf3	550e8400-e29b-41d4-a716-446655440001	["investor"]	pending	\N
frontend-debug@example.com	Frontend Debug Test	$2a$10$mkbxPMeJPSly74R7OqYogOcAxXAWWmp1XbKgxGMYKSrIGkaUMyUSi	+62-817-6666-7777	Jl. Frontend Debug No. 789, Jakarta	t	2025-09-19 22:00:22.225467+07	2025-09-19 22:00:22.225467+07	a6778c6f-e264-4a88-aa00-ea8608508c85	550e8400-e29b-41d4-a716-446655440001	["investor"]	pending	\N
testbusinessowner@hajifund.com	Test Business Owner	$2a$10$koEOXil5DxHdvbnCjPj.qu1a/Q1yoNBBEhU9xBXDOT55UTbw7ioei	+62-800-TEST-01	Jl. Test Business Owner No. 1	t	2025-09-20 10:32:00.570731+07	2025-09-20 10:32:00.570731+07	da1fe18e-3f74-468a-b2a7-6e4eee47f785	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N
testbusinessowner1758339647@hajifund.com	Test Business Owner	$2a$10$4vVqfyL1/jg5UTDANUb3A.wnC751am0lgOGYC9DtldPRaYODikSSS	+62-800-TEST-01	Jl. Test Business Owner No. 1	t	2025-09-20 10:40:48.107869+07	2025-09-20 10:40:48.107869+07	d065d35d-f2dd-453c-83ac-8fbbedecc79b	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N
debugowner3@hajifund.com	Debug Owner 3	$2a$10$x/wBJVnADWHyPO4bfx95ceHqR6I9jGFb57lBOnso01oBspvlmtFZm	+62-800-DEBUG3	Jl. Debug Owner 3 No. 1	t	2025-09-20 10:43:58.39568+07	2025-09-20 10:43:58.39568+07	b3203c01-18cf-4bdb-9e48-d6e57e556f26	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N
frontendtest@example.com	Demo Investor	$2a$10$oxM3XJivI2zKY5bhLkV69O5d3siH5N2/1nOsMnKtl/EykvnBMEsL6	+6281234567891	Jl. Demo Investor No. 456, Jakarta	t	2025-10-05 09:59:42.464019+07	2025-10-05 09:59:42.464019+07	123e4567-e89b-12d3-a456-426614174002	550e8400-e29b-41d4-a716-446655440002	["member", "business_owner"]	pending	\N
admin@hajifund.com	Admin HajiFund	$2a$10$x/YiTcPGnJqhfdLF.uV9T./qZmxHyKshWbM8bNdAk8qCHkzzKQKyq	+62-800-ADMIN-01	Jl. Admin HajiFund No. 1, Jakarta Pusat	f	2025-09-19 23:24:07.614173+07	2025-10-05 10:01:58.002883+07	2b941420-1c2d-4ffb-bef9-37e34a891cb6	\N	["admin"]	pending	\N
abcd@gmail.com	Alkha	$2a$10$LLmvKz53.0Y/k62jpWL4MOwBPZPjjauh663bPJcUfjwz6SorCnJka	081285019915	Alamat Palsu	t	2025-10-11 11:38:44.921583+07	2025-10-11 11:38:44.921583+07	e31382fb-baf0-43c5-bd27-5c54a28ed8a9	550e8400-e29b-41d4-a716-446655440001	["investor"]	pending	\N
user1@hajifund.id	User1	$2a$10$pfSR2kAgKu5WidBGEMgBre51VKaMHFe1wHxesaYN50PHLvvfVyUny	081110100101	Jl. Dr Djunjunan Bandung	t	2025-10-18 11:36:50.758261+07	2025-10-18 11:36:50.758261+07	7f8c88b9-2ec9-4e0a-95f0-695ed9dca856	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner"]	pending	\N
\.


ALTER TABLE public.users ENABLE TRIGGER ALL;

--
-- TOC entry 3784 (class 0 OID 17529)
-- Dependencies: 219
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.projects DISABLE TRIGGER ALL;

COPY public.projects (id, title, description, business_id, funding_goal, minimum_funding, current_funding, funding_deadline, profit_sharing_ratio, project_type, status, milestones, documents, created_at, updated_at, project_image_1, project_image_2, project_image_3, min_investment, risk_level, investment_period, expected_return, start_date, end_date, target_amount, raised_amount, category, owner_id, cooperative_id, approved_by, approved_at, approval_status, rejected_by, rejected_at, rejection_reason, reviewer_comments, sharia_compliant) FROM stdin;
11111111-1111-1111-1111-111111111111	Ekspansi Warung Makan Padang	Membuka cabang baru warung makan Padang di lokasi strategis untuk meningkatkan jangkauan pasar	09176669-b045-4e33-8ae2-8febe34a16cf	75000000.00	\N	0.00	\N	{"business": 30, "investor": 70}	expansion	draft	[]	{}	2025-10-08 23:29:17.013744+07	2025-10-08 23:29:17.013744+07	\N	\N	\N	1000000.00	Medium	12	15-20% per tahun	\N	\N	75000000.00	0.00	Food & Beverage	550e8400-e29b-41d4-a716-446655440000	550e8400-e29b-41d4-a716-446655440001	\N	\N	pending	\N	\N	\N	\N	f
22222222-2222-2222-2222-222222222222	Pembelian Mesin Jahit Industri	Investasi untuk mesin jahit industri guna meningkatkan produksi konveksi dan kualitas produk	09176669-b045-4e33-8ae2-8febe34a16cf	50000000.00	\N	10000000.00	\N	{"business": 30, "investor": 70}	equipment	active	[]	{}	2025-10-08 23:29:17.013744+07	2025-10-08 23:29:17.013744+07	\N	\N	\N	500000.00	Low	18	12-18% per tahun	\N	\N	50000000.00	10000000.00	Manufacturing	550e8400-e29b-41d4-a716-446655440000	550e8400-e29b-41d4-a716-446655440001	\N	\N	approved	\N	\N	\N	\N	f
33333333-3333-3333-3333-333333333333	Renovasi Toko Kelontong	Renovasi dan perluasan toko kelontong untuk meningkatkan pelayanan kepada pelanggan	09176669-b045-4e33-8ae2-8febe34a16cf	30000000.00	\N	15000000.00	\N	{"business": 30, "investor": 70}	expansion	active	[]	{}	2025-10-08 23:29:17.013744+07	2025-10-08 23:29:17.013744+07	\N	\N	\N	300000.00	Low	24	10-15% per tahun	\N	\N	30000000.00	15000000.00	Retail	550e8400-e29b-41d4-a716-446655440000	550e8400-e29b-41d4-a716-446655440001	\N	\N	approved	\N	\N	\N	\N	f
44444444-4444-4444-4444-444444444444	Pembangunan Kios Pasar	Membangun kios di pasar tradisional untuk berjualan sayuran dan kebutuhan sehari-hari	09176669-b045-4e33-8ae2-8febe34a16cf	40000000.00	\N	0.00	\N	{"business": 30, "investor": 70}	startup	cancelled	[]	{}	2025-10-08 23:29:17.013744+07	2025-10-08 23:29:17.013744+07	\N	\N	\N	500000.00	High	36	20-25% per tahun	\N	\N	40000000.00	0.00	Real Estate	550e8400-e29b-41d4-a716-446655440000	550e8400-e29b-41d4-a716-446655440001	\N	\N	rejected	\N	\N	\N	\N	f
55555555-5555-5555-5555-555555555555	Pembuatan Website Toko Online	Pengembangan website e-commerce untuk toko elektronik dengan fitur payment gateway	09176669-b045-4e33-8ae2-8febe34a16cf	25000000.00	\N	5000000.00	\N	{"business": 30, "investor": 70}	expansion	active	[]	{}	2025-10-08 23:29:17.013744+07	2025-10-08 23:29:17.013744+07	\N	\N	\N	200000.00	Medium	12	18-22% per tahun	\N	\N	25000000.00	5000000.00	Technology	550e8400-e29b-41d4-a716-446655440000	550e8400-e29b-41d4-a716-446655440001	\N	\N	approved	\N	\N	\N	\N	f
\.


ALTER TABLE public.projects ENABLE TRIGGER ALL;

--
-- TOC entry 3786 (class 0 OID 17564)
-- Dependencies: 221
-- Data for Name: investments; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.investments DISABLE TRIGGER ALL;

COPY public.investments (id, project_id, investor_id, amount, investment_date, profit_sharing_percentage, status, transaction_ref, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.investments ENABLE TRIGGER ALL;

--
-- TOC entry 3787 (class 0 OID 17599)
-- Dependencies: 222
-- Data for Name: profit_distributions; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.profit_distributions DISABLE TRIGGER ALL;

COPY public.profit_distributions (id, project_id, business_profit, distribution_date, total_distributed, status, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.profit_distributions ENABLE TRIGGER ALL;

--
-- TOC entry 3788 (class 0 OID 17616)
-- Dependencies: 223
-- Data for Name: investment_returns; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.investment_returns DISABLE TRIGGER ALL;

COPY public.investment_returns (id, investment_id, distribution_id, return_amount, return_percentage, payment_date, status, transaction_ref, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.investment_returns ENABLE TRIGGER ALL;

--
-- TOC entry 3798 (class 0 OID 0)
-- Dependencies: 220
-- Name: global_transaction_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.global_transaction_seq', 1000000, false);


--
-- TOC entry 3799 (class 0 OID 0)
-- Dependencies: 227
-- Name: idempotency_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.idempotency_sequence', 1, false);


-- Completed on 2025-10-19 22:16:23 WIB

--
-- PostgreSQL database dump complete
--

