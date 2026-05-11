--
-- PostgreSQL database dump
--

\restrict aZBllqFOU2l0NStFffiRTuA9mujQhNzqbmTRXyLEYqPPrgPL5FiJ3RxLdMbthPg

-- Dumped from database version 15.17
-- Dumped by pg_dump version 15.17

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
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    username character varying(255),
    action character varying(50),
    resource_type character varying(50),
    resource_id character varying(255),
    resource_name character varying(255),
    detail text,
    ip_address character varying(100),
    user_agent character varying(500),
    success boolean DEFAULT true,
    error_message text,
    created_at timestamp with time zone
);


ALTER TABLE public.audit_logs OWNER TO registry;

--
-- Name: blobs; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.blobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    digest character varying(71) NOT NULL,
    size bigint NOT NULL,
    storage_path character varying(512),
    content_type character varying(255),
    last_accessed timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.blobs OWNER TO registry;

--
-- Name: manifest_blobs; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.manifest_blobs (
    blob_id uuid DEFAULT gen_random_uuid() NOT NULL,
    manifest_id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.manifest_blobs OWNER TO registry;

--
-- Name: manifests; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.manifests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    repository_id uuid NOT NULL,
    digest character varying(71) NOT NULL,
    media_type character varying(255),
    config_digest character varying(71),
    config_size bigint,
    layers_count bigint,
    total_size bigint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.manifests OWNER TO registry;

--
-- Name: namespaces; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.namespaces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    display_name character varying(255),
    description text,
    is_public boolean DEFAULT true,
    owner_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.namespaces OWNER TO registry;

--
-- Name: registry_endpoints; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.registry_endpoints (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    url character varying(512) NOT NULL,
    type character varying(20),
    auth_type character varying(20),
    username character varying(255),
    password character varying(255),
    access_token text,
    refresh_token text,
    insecure_skip_verify boolean DEFAULT false,
    timeout_seconds bigint DEFAULT 30,
    is_enabled boolean DEFAULT true,
    last_test_time timestamp with time zone,
    last_test_result boolean,
    last_error_message text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.registry_endpoints OWNER TO registry;

--
-- Name: replication_policies; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.replication_policies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    source_registry character varying(255) NOT NULL,
    source_namespace character varying(255),
    source_repository character varying(255),
    source_tag_pattern character varying(255),
    dest_registry character varying(255) NOT NULL,
    dest_namespace character varying(255),
    dest_repository character varying(255),
    trigger_type character varying(20) NOT NULL,
    trigger_cron character varying(50),
    trigger_event character varying(50),
    delete_remote boolean DEFAULT false,
    override boolean DEFAULT true,
    enabled boolean DEFAULT true,
    last_trigger_time timestamp with time zone,
    last_success_time timestamp with time zone,
    last_failure_time timestamp with time zone,
    success_count bigint DEFAULT 0,
    failure_count bigint DEFAULT 0,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.replication_policies OWNER TO registry;

--
-- Name: replication_task_details; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.replication_task_details (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid NOT NULL,
    resource_type character varying(20) NOT NULL,
    source_namespace character varying(255),
    source_repository character varying(255),
    source_tag character varying(255),
    source_digest character varying(71),
    status character varying(20),
    dest_namespace character varying(255),
    dest_repository character varying(255),
    dest_tag character varying(255),
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    bytes_transferred bigint,
    error_message text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.replication_task_details OWNER TO registry;

--
-- Name: replication_tasks; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.replication_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    policy_id uuid,
    status character varying(20) NOT NULL,
    source_registry character varying(255),
    dest_registry character varying(255),
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    total_resources bigint DEFAULT 0,
    succeeded_count bigint DEFAULT 0,
    failed_count bigint DEFAULT 0,
    skipped_count bigint DEFAULT 0,
    error_message text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    progress integer DEFAULT 0
);


ALTER TABLE public.replication_tasks OWNER TO registry;

--
-- Name: repositories; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.repositories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_public boolean DEFAULT true,
    owner_id uuid,
    pull_count bigint DEFAULT 0,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.repositories OWNER TO registry;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    repository_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    manifest_id uuid NOT NULL,
    pushed_by character varying(255),
    pushed_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.tags OWNER TO registry;

--
-- Name: users; Type: TABLE; Schema: public; Owner: registry
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    email character varying(255),
    display_name character varying(255),
    is_admin boolean DEFAULT false,
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO registry;

--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.audit_logs (id, user_id, username, action, resource_type, resource_id, resource_name, detail, ip_address, user_agent, success, error_message, created_at) FROM stdin;
5242f44a-b802-45b9-b26c-4850fc8de173	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	192.168.50.243	curl/8.7.1	t		2026-05-07 02:18:27.948187+00
97da80f0-32bd-46d1-9313-7a55592a459b	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	192.168.50.243	curl/8.7.1	t		2026-05-07 02:21:34.301+00
96bcc643-1329-4129-bf73-802ac292a21d	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	user	94e9ed02-1f17-458e-af18-00fc6e41938b	ceshi1	创建用户	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 02:24:57.449356+00
c9cf1e04-ce81-4b6a-827c-23925d5cb938	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	user	4c3c6ceb-acae-4a2b-b0c1-0bd86da363d4	1111	创建用户	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 02:27:29.948786+00
3e7a5853-861e-4845-9bb5-895195e90424	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	user	367f2079-1d2e-4093-811a-0e023d94805b	222222	创建用户	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 02:27:38.116924+00
22a2dac9-75c3-43a5-9937-cad61f4e25e8	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	user	c3efd9e1-a8ca-462b-9d87-08380aa4c53d	33333333	创建用户	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 02:27:47.389503+00
a9527f8e-fcb0-4d85-b224-989b1e16bf23	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 02:30:36.73427+00
faebc388-648c-4eb0-96bc-0e99d1de4149	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	repository	3e7fef21-8c67-4a8f-a026-cee770d974f5	222	在命名空间 222 下创建仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 02:41:22.810197+00
39cbae9e-4c0f-4047-ac72-c5eef4678a02	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		222/222:1.0	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 03:17:46.273641+00
7b980d31-307b-44cc-8229-06a87b2549cb	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		222/222:1.0	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 03:17:56.535337+00
c3b0fab1-14ef-4b76-be5c-8d16aac5533a	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		11111/2222:latest	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 03:29:28.558164+00
6c817c03-0c30-4b85-bfda-60c2a5168d03	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		222/222:1.0	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 03:29:31.670706+00
a575d9f4-35e1-4d5a-8e66-c47ab307fe23	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		222/222:1.0	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 04:27:29.495523+00
e74c9198-96ec-4497-bc86-2f16efe4073e	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 04:35:22.854851+00
d1d50672-f93e-4eb9-8715-06e56fdf95d2	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 04:44:30.602991+00
2ed28ebf-59e4-45b5-83b4-97ba5a9c7e6f	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 05:37:57.150806+00
0db5768a-9d0d-4ca7-87d3-e29ac227e37d	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	192.168.50.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-07 14:42:24.038959+00
e86793e2-75ff-4d1b-8b1a-86cffcce3d8f	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	192.168.50.1	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1	t		2026-05-07 16:05:33.453745+00
5837f3b7-7c9d-4956-adb7-48dfe84ac6cd	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	192.168.50.1	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1	t		2026-05-07 16:07:05.293483+00
7af33449-13b5-416e-bdc6-d89598a1e5b7	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	192.168.50.1	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1	t		2026-05-07 21:09:11.20338+00
6d9b8524-c627-4a0e-bb4f-40745fd02591	5c894435-98c8-4ee3-8008-5c99311801fa	admin	update	user	c3efd9e1-a8ca-462b-9d87-08380aa4c53d	33333333	更新用户信息	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 00:50:54.492369+00
6aaf09e8-4d33-4cca-a744-412887a4c627	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	user	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	创建用户	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 00:55:12.252517+00
25fe2fe6-4f0b-4e33-83a8-96780e4433ce	\N		login	system	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 00:55:22.948547+00
36df4cf9-2cff-42b6-8924-7014f7c8f938	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	create	namespace	d3939621-c03c-4f4a-8d3f-05e9aad02cb9	nginx	创建命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 01:17:41.349796+00
6c7f218e-c907-4da0-9e1c-423ff7b3a260	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	create	repository	4ea614ce-a986-4487-b62f-f4b66d0a9f09	nginx	在命名空间 nginx 下创建仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 01:17:52.18702+00
00387628-55c3-41cf-aebd-9b4053e6cd1e	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:42:29.899729+00
2fca31b3-32b7-46b1-8a63-54b6a9614a69	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	namespace	bd0a2e39-ca61-4175-95f2-86e93fab7225	jjjj	创建命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:43:33.022887+00
03117009-bac6-4cac-bcbf-9e363b7a887e	\N		login	system			用户登录失败：密码错误	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	Invalid username or password	2026-05-08 03:43:53.346699+00
e0507b3d-7fca-42a0-9849-feec0efcf182	\N		login	system	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:44:01.742761+00
dc5cfae5-be63-4338-9df3-c5885df76af3	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:44:25.478832+00
c46f6fd1-64c7-4718-b626-3c8457f1316e	\N		login	system	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:47:55.082545+00
1d09a91b-c359-420d-a6c9-70dc183c6b97	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	download	image		222/222:1.0	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:48:12.689494+00
e13d8d42-055d-49ba-9c75-95386fa78da3	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	upload	image		222/222:qqh9n	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:49:24.283462+00
89d27918-bd2e-484c-b5d6-a45c3b42cf39	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	download	image		222/222:qqh9n	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 03:49:30.121316+00
c92b37a5-80cd-4d7a-bd79-ba92cfcadb8a	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	download	image		222/222:qqh9n	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:23:33.759819+00
213138ef-6f2d-4afa-9c5a-f29061d31328	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	download	image		222/222:1.0	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:23:36.198508+00
5a8791bc-164a-45f3-adba-4e96ce53086a	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:23:44.428932+00
8b375894-972c-4f48-ba49-e72a47e7b90f	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		11111/2222:alpine	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:23:53.38435+00
e5cdae07-0730-4745-8fd5-99ccd20aa057	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		11111/2222:1.0	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:23:57.35415+00
7eeb5cd3-4e42-4c85-8487-29ba81902e63	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		11111/2222:2.12.1	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:09.651617+00
fa294b82-3dc9-491b-adfe-48a299f716c9	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		11111/2222:latest	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:10.623696+00
0b1e78f7-0fc9-4ed2-b802-e78155c12b56	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	2a229c56-d1a5-4ac7-88fb-c7d4bad6f9b9	2.12.1	删除仓库 2222 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:15.229183+00
cc2c60eb-099f-4056-88c4-3c4b2e8bde2b	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	849ef378-a4b4-4b32-8d26-01f75a796fc7	latest	删除仓库 2222 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:17.170394+00
ba4b591f-230d-4846-9cec-1c1266682164	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	d9ab9ea2-8838-4ea9-99cb-7748e7fafc4f	1.0	删除仓库 2222 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:19.946987+00
753c1fa2-5e3d-4abc-88db-08b462f639dc	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	9ec138ed-3b24-4309-bbf9-a7fec73b052c	alpine	删除仓库 2222 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:21.799065+00
a37df422-cf08-4557-89bc-9dd338163c5b	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	namespace	bd0a2e39-ca61-4175-95f2-86e93fab7225	jjjj	删除命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:29.7114+00
fbd76fae-7784-42b5-becc-cc7d5cef5a09	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	repository	4ea614ce-a986-4487-b62f-f4b66d0a9f09	nginx	删除仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:38.620574+00
53a81da8-21a5-44e9-8785-db5c8b0b7dca	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	namespace	cf9da0d8-90d3-4024-9639-49f8eb671e80	3333	删除命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:43.852739+00
ae5a5040-236f-481b-a17d-d682d82e7504	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	d11a0cfe-e1ab-41e7-acf6-19e7630c5010	qqh9n	删除仓库 222 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:49.031477+00
aaf92d47-9e37-4518-8d06-daf165b86afb	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	82c06075-acff-403b-9237-ceac7a9ef46b	1.0	删除仓库 222 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:50.70503+00
59112c40-5a90-477e-bc54-b989b9a19d35	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	repository	3e7fef21-8c67-4a8f-a026-cee770d974f5	222	删除仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:53.92424+00
b0186d6c-cd74-424f-bc19-17098d0c2c50	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	namespace	7d5c8af3-f945-4eaf-82de-c87461bf0c32	222	删除命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:24:58.432985+00
b64d4b0f-6067-45d4-a202-437df8432bbb	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	repository	13c059d3-5090-4ebf-85c4-3a582584cea7	2222	删除仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:25:12.98967+00
aee2e72d-61fc-40f3-bab0-5c2541efd54a	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	namespace	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	11111	删除命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:25:16.85782+00
0627dcc6-f7a6-40dd-bdf2-fe7172bc2e4e	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	repository	4ea614ce-a986-4487-b62f-f4b66d0a9f09	nginx	恢复已删除的仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:25:25.261177+00
017b9608-7b5b-44f8-aaab-3c8a66484a7c	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		nginx/nginx:dar9o	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:26:11.888065+00
362e1c31-193a-48bb-b096-e0c916a244ae	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/nginx:dar9o	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 04:26:16.316222+00
d7ec68d7-e373-4a35-93a2-e4319a23466f	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/nginx:dar9o	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 05:30:10.457115+00
93522a27-b2a6-4089-aee3-a8d00805dc2f	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		nginx/nginx:b5h0m	镜像上传失败	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	创建manifest失败: ERROR: duplicate key value violates unique constraint "idx_repo_digest" (SQLSTATE 23505)	2026-05-08 05:30:46.192973+00
fffae69a-be39-4a62-95a1-7383170047c1	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	feee2c16-b2cd-482e-97e7-6faefc4c0998	dar9o	删除仓库 nginx 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 05:30:55.555357+00
32da5288-c8ed-46f6-b67f-fd0c2f3edf10	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/nginx:b5h0m	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 05:31:08.161497+00
f55f5e7c-ab99-41d7-b2fc-e14d4eed75ff	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		nginx/nginx:z22t3	镜像上传失败	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	创建manifest失败: ERROR: duplicate key value violates unique constraint "idx_repo_digest" (SQLSTATE 23505)	2026-05-08 05:32:20.529143+00
8d14ef94-4640-45c6-b27f-162e192bccfd	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	00e8815f-ec79-48d0-ac1c-29bd914c4289	z22t3	删除仓库 nginx 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 05:39:05.953431+00
6ab6a5f1-4f2b-42b5-a5e7-33b7cccf89d5	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	ce46424d-14db-424c-bf45-6d775ba64c07	b5h0m	删除仓库 nginx 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 05:39:07.937053+00
b9ea5a3c-a69d-4a8e-9a97-3a7b74eaf4f0	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		nginx/nginx:bpcis	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 05:40:52.341826+00
e7d75215-705d-402d-a62d-76cdd71744f2	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	repository	d15e9e85-a189-4759-a386-840ac511fd86	redis	在命名空间 nginx 下创建仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:10:48.837326+00
e9d627ef-1bb0-44a2-840f-8670b8625f8f	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		nginx/redis:n9ss7	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:11:23.741572+00
05b6d766-56ab-45cc-af57-489f6e2ca3c6	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/redis:n9ss7	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:11:34.031353+00
b7da545b-bfb9-4484-8251-1eecbd80d2ab	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	ec67a476-32f6-48de-a465-ab3fe1aae153	bpcis	删除仓库 nginx 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:12:45.408709+00
e48470af-e138-47c9-92a7-9500968372c1	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	63d3ecee-6103-4411-9c6a-e067086a1633	n9ss7	删除仓库 redis 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:20:38.592189+00
2220e943-ab64-4332-b2c4-eff3e4d6fbbf	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	repository	31c7d765-af92-4f0a-855c-22fc9bc1aa82	fastdfs	在命名空间 nginx 下创建仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:20:51.597701+00
4a33cb44-6647-49d8-abc2-9dad69da551f	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		nginx/fastdfs:m008d	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:22:57.333982+00
db6f94af-9b69-4f89-b10a-44b366325514	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/fastdfs:m008d	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:23:03.090703+00
925eb679-4be6-4cbd-8a48-9afccf0a80cb	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/fastdfs:m008d	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:23:32.6198+00
d39ce8e0-d39f-481b-93a1-b04f36e13ab3	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/fastdfs:m008d	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:26:36.482854+00
da664103-d148-4fc2-825a-c62fd87b711c	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/fastdfs:m008d	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:27:20.867114+00
3140aafc-4c5a-4a10-bf1b-747ed51acbcf	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/fastdfs:m008d	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:31:35.655803+00
3ded3bd5-70a3-4417-8271-1b1f69a053c7	\N		login	system	5c894435-98c8-4ee3-8008-5c99311801fa	admin	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:31:36.960694+00
de43fbc1-63a9-4a35-a40a-c1ede6db4f8c	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/fastdfs:m008d	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:32:04.638978+00
479ac1fc-38b9-4e8f-9638-8f97d5f47ced	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		nginx/fastdfs:m008d	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:32:40.544046+00
935dd96c-15a2-4ddf-a291-f345ea36ae32	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	tag	793246ea-efc2-4124-aad9-0ce1d078aec7	m008d	删除仓库 fastdfs 的标签	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:32:43.339366+00
17e27037-165f-4045-b9b8-7bec12eab8f1	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	repository	31c7d765-af92-4f0a-855c-22fc9bc1aa82	fastdfs	删除仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:32:47.005234+00
c03660ac-604b-45bc-9a73-855c2df241ff	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	repository	d15e9e85-a189-4759-a386-840ac511fd86	redis	删除仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:32:48.864289+00
68c65672-697e-463e-920e-7dc283e3be09	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	repository	4ea614ce-a986-4487-b62f-f4b66d0a9f09	nginx	删除仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:32:51.631431+00
5866a35a-9eb5-4982-9c6a-ec57590e68cf	5c894435-98c8-4ee3-8008-5c99311801fa	admin	delete	namespace	d3939621-c03c-4f4a-8d3f-05e9aad02cb9	nginx	删除命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:33:18.337325+00
9d9d43cd-ff1c-418e-9c57-e31594b317db	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	namespace	488702f2-5cd8-4a8f-a054-10c3a2926581	psychocare	创建命名空间	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:33:30.160874+00
d8792547-9dfa-49bd-b770-62f2298ad34c	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	repository	58035b84-fa3c-4fa4-907a-591eda623b48	mysql	在命名空间 psychocare 下创建仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:33:38.525408+00
b6dc2450-85a5-40be-95ae-3da91e383c70	5c894435-98c8-4ee3-8008-5c99311801fa	admin	create	repository	f96e7bab-f4a5-45cc-bbc7-f7b0d27b264d	redis	在命名空间 psychocare 下创建仓库	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:34:05.799051+00
68ddf319-a668-4c28-ad6c-cbe4fe6192a8	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		psychocare/redis:7	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:34:45.843329+00
c264a027-ff48-48a5-9d03-82cd35a02915	5c894435-98c8-4ee3-8008-5c99311801fa	admin	download	image		psychocare/redis:7	镜像导出下载	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:35:34.672377+00
e672ab4d-8bba-46c9-8953-d138882c088b	\N		login	system	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:37:55.238446+00
151a7404-fa1f-411e-a1a6-153c8156eefc	\N		login	system	52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	用户登录成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:49:51.948353+00
9e5370cd-0cfe-4941-8ca4-8098918e15db	5c894435-98c8-4ee3-8008-5c99311801fa	admin	upload	image		psychocare/mysql:5.7	镜像上传成功	220.180.238.112	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t		2026-05-08 06:36:05.299983+00
\.


--
-- Data for Name: blobs; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.blobs (id, digest, size, storage_path, content_type, last_accessed, created_at, updated_at, deleted_at) FROM stdin;
a454b383-9444-4b0f-a5b4-ec94d4c31cb7	sha256:361b78afe6648f0999af7423e4dbfe795380b4666694d0c5fef3233e009ae4fd	356	/data/blobs/111/111/361b78afe6648f0999af7423e4dbfe795380b4666694d0c5fef3233e009ae4fd.blob	application/json	\N	2026-04-27 09:58:55.275061+00	2026-04-27 09:58:55.275061+00	\N
39d93c25-f550-489b-b0f8-2d341b928536	sha256:4e921a79d13d577cc206b67931bcc5d424040dd2d04cf8c94c4d03428a009834	482	/data/blobs/111/111/4e921a79d13d577cc206b67931bcc5d424040dd2d04cf8c94c4d03428a009834.blob	application/octet-stream	\N	2026-04-27 09:58:55.286848+00	2026-04-27 09:58:55.286848+00	\N
eb6e370f-ba4c-4984-9992-6e98f1e1570b	sha256:8b2952eb02aac23a82803bf3e25d94ea78f3d4674d972cc7324a712ad9d54b6f	2383360	/data/blobs/111/111/8b2952eb02aac23a82803bf3e25d94ea78f3d4674d972cc7324a712ad9d54b6f.blob	application/octet-stream	\N	2026-04-27 09:58:55.303484+00	2026-04-27 09:58:55.303484+00	\N
09a5bb08-ee49-4c21-9e14-0d7ebbf83175	sha256:73cb62467b8f9e06265bc00441cc3d8026d24ca3708d517a3df93ff5a787af77	17408	/data/blobs/111/111/73cb62467b8f9e06265bc00441cc3d8026d24ca3708d517a3df93ff5a787af77.blob	application/octet-stream	\N	2026-04-27 09:58:55.336163+00	2026-04-27 09:58:55.336163+00	\N
82bbfb3f-0740-4bde-8c31-beac666a0cf8	sha256:90e9a2126375f57b65894abc8f4ed75b790430b5281afdc9a401f57dd0b11cc4	482	/data/blobs/111/111/90e9a2126375f57b65894abc8f4ed75b790430b5281afdc9a401f57dd0b11cc4.blob	application/octet-stream	\N	2026-04-27 09:58:55.340567+00	2026-04-27 09:58:55.340567+00	\N
3e91cf30-c159-4f14-9c46-1e59546edd47	sha256:b5de8651b2a29bcaf3c595c5589f632437b01e28edf190385427f64cd6313fca	482	/data/blobs/111/111/b5de8651b2a29bcaf3c595c5589f632437b01e28edf190385427f64cd6313fca.blob	application/octet-stream	\N	2026-04-27 09:58:55.34524+00	2026-04-27 09:58:55.34524+00	\N
257f8e9a-0040-4ae6-97d3-f3d0712a4830	sha256:e27ac3ced2c27d463ea1d02749d1dad3b245b91dd7e82972f3a9e18aaa63a1ed	482	/data/blobs/111/111/e27ac3ced2c27d463ea1d02749d1dad3b245b91dd7e82972f3a9e18aaa63a1ed.blob	application/octet-stream	\N	2026-04-27 09:58:55.350348+00	2026-04-27 09:58:55.350348+00	\N
28ad533a-0a56-4072-9626-c2e24fa029ea	sha256:eb85e5234731d6358479194299fc6ead43dc953783facbc3599aca225f8de4fc	482	/data/blobs/111/111/eb85e5234731d6358479194299fc6ead43dc953783facbc3599aca225f8de4fc.blob	application/octet-stream	\N	2026-04-27 09:58:55.355504+00	2026-04-27 09:58:55.355504+00	\N
5e2f8ae7-a0b3-47ab-ac83-88fe8dac032b	sha256:	0	/data/blobs/111/111/.blob	application/octet-stream	\N	2026-04-27 09:58:55.362909+00	2026-04-27 09:58:55.362909+00	\N
1e512a8b-0a0d-438d-a05d-4ac689a7d87e	sha256:163aa30a8a1281f99f36a23166376c792481cde55275fa8350ef7aaf7b2f7be7	482	/data/blobs/111/111/163aa30a8a1281f99f36a23166376c792481cde55275fa8350ef7aaf7b2f7be7.blob	application/octet-stream	\N	2026-04-27 09:58:55.365452+00	2026-04-27 09:58:55.365452+00	\N
d1664af4-a335-401c-8fcf-7631a7c2627e	sha256:441e16cac4fe6b7abab2653886fbab030752e42c42bd508f1fa2f7f8c5df0fcf	1536	/data/blobs/111/111/441e16cac4fe6b7abab2653886fbab030752e42c42bd508f1fa2f7f8c5df0fcf.blob	application/octet-stream	\N	2026-04-27 09:58:55.374745+00	2026-04-27 09:58:55.374745+00	\N
e6463b72-49bf-4561-81a4-d7a9f768deb6	sha256:532b66f4569dfab5f87219c302ea23478e6ad9504863f2a7410c935593e6b526	3072	/data/blobs/111/111/532b66f4569dfab5f87219c302ea23478e6ad9504863f2a7410c935593e6b526.blob	application/octet-stream	\N	2026-04-27 09:58:55.377275+00	2026-04-27 09:58:55.377275+00	\N
bd1b706a-4e3e-448a-a4bc-51359bf04add	sha256:7ff7abf4911b44c1b705de478892bac6d01821c65ebc2993edb87136d51eb670	11264	/data/blobs/111/111/7ff7abf4911b44c1b705de478892bac6d01821c65ebc2993edb87136d51eb670.blob	application/octet-stream	\N	2026-04-27 09:58:55.382496+00	2026-04-27 09:58:55.382496+00	\N
c2a1e715-8894-4bcb-a8de-582b5bc262ce	sha256:8527ccd6bd857b844293f9efe34222229fa76e040d55dd03e019f305f7bd2a74	7168	/data/blobs/111/111/8527ccd6bd857b844293f9efe34222229fa76e040d55dd03e019f305f7bd2a74.blob	application/octet-stream	\N	2026-04-27 09:58:55.385555+00	2026-04-27 09:58:55.385555+00	\N
8ddac311-58cf-45c7-8e25-af2ef8584fa9	sha256:af5f1e8a810c51595f6c04d61e33bb75fd55ba240e9d4cd6cfd6bd24afc405c4	406	/data/blobs/111/111/af5f1e8a810c51595f6c04d61e33bb75fd55ba240e9d4cd6cfd6bd24afc405c4.blob	application/octet-stream	\N	2026-04-27 09:58:55.396459+00	2026-04-27 09:58:55.396459+00	\N
50d57999-f255-468f-9e19-c9809dc694aa	sha256:cff044e186247f93aa52554c96d77143cc92f99b2b55914038d0941fddeb6623	145024000	/data/blobs/111/111/cff044e186247f93aa52554c96d77143cc92f99b2b55914038d0941fddeb6623.blob	application/octet-stream	\N	2026-04-27 09:58:55.632802+00	2026-04-27 09:58:55.632802+00	\N
f4798970-62a5-432d-a2c3-47201a455499	sha256:0b14b8e5c533fb43d07327fa8fe6c7393358002310d9f0d01976d387822a1bd3	1921	/data/blobs/111/111/0b14b8e5c533fb43d07327fa8fe6c7393358002310d9f0d01976d387822a1bd3.blob	application/octet-stream	\N	2026-04-27 09:58:55.640268+00	2026-04-27 09:58:55.640268+00	\N
14c97dfe-4c30-48b2-b432-7660475ccd47	sha256:0d9e9a9ce9e415229fa3c1953ec32c236bfde6a825f4a74a78013586071c02e8	79375872	/data/blobs/111/111/0d9e9a9ce9e415229fa3c1953ec32c236bfde6a825f4a74a78013586071c02e8.blob	application/octet-stream	\N	2026-04-27 09:58:55.988964+00	2026-04-27 09:58:55.988964+00	\N
a35c648a-1b49-41aa-95be-a01d5c22292a	sha256:4555572a6bb29d49eb9dbd1fb0938788ca7d772f441f8273626f1a12933fcee3	3072	/data/blobs/111/111/4555572a6bb29d49eb9dbd1fb0938788ca7d772f441f8273626f1a12933fcee3.blob	application/octet-stream	\N	2026-04-27 09:58:56.266078+00	2026-04-27 09:58:56.266078+00	\N
e47acf17-1a10-420b-88d3-756bf9de18eb	sha256:d76a5f910f6ba5bce12b14e396f8386d385d62bbc4c9d82af25ae956c11bb3aa	13914112	/data/blobs/111/111/d76a5f910f6ba5bce12b14e396f8386d385d62bbc4c9d82af25ae956c11bb3aa.blob	application/octet-stream	\N	2026-04-27 09:58:56.292112+00	2026-04-27 09:58:56.292112+00	\N
ccb6654f-2b38-4961-98bf-7fc4bbcc5739	sha256:452976015fbeae55c2afb36fe3003262065b803ad2c5b616007adbf5f4baa7f6	482	/data/blobs/111/111/452976015fbeae55c2afb36fe3003262065b803ad2c5b616007adbf5f4baa7f6.blob	application/octet-stream	\N	2026-04-27 09:58:56.294581+00	2026-04-27 09:58:56.294581+00	\N
9f5a73ff-1a14-44cc-a344-0b9de6b9399c	sha256:5107333e08a87b836d48ff7528b1e84b9c86781cc9f1748bbc1b8c42a870d933	7191	/data/blobs/111/111/5107333e08a87b836d48ff7528b1e84b9c86781cc9f1748bbc1b8c42a870d933.blob	application/octet-stream	\N	2026-04-27 09:58:56.297725+00	2026-04-27 09:58:56.297725+00	\N
98b8fdb4-2996-4218-b093-f900afd52a5d	sha256:e02f4f87b71da2cbd91a1b2d32b1f177ec7a88c272f202cc7ac2ef9bc145ae90	482	/data/blobs/111/111/e02f4f87b71da2cbd91a1b2d32b1f177ec7a88c272f202cc7ac2ef9bc145ae90.blob	application/octet-stream	\N	2026-04-27 09:58:56.300673+00	2026-04-27 09:58:56.300673+00	\N
88ec95f8-5913-4007-864f-0d4a6f568e30	sha256:272c7ce191447e5d22b60abcef1014fbd6c8bfaeddbdb3c874c65a3a13bf4a0e	482	/data/blobs/111/111/272c7ce191447e5d22b60abcef1014fbd6c8bfaeddbdb3c874c65a3a13bf4a0e.blob	application/octet-stream	\N	2026-04-27 09:58:56.303087+00	2026-04-27 09:58:56.303087+00	\N
5217898a-67cd-44e1-a39c-403a2d4ca2b2	sha256:337ec6bae2225e56895f25ef88a874b2796e020332d63a35929f40e9e7fa158e	278817280	/data/blobs/111/111/337ec6bae2225e56895f25ef88a874b2796e020332d63a35929f40e9e7fa158e.blob	application/octet-stream	\N	2026-04-27 09:58:56.641821+00	2026-04-27 09:58:56.641821+00	\N
5db441cf-2b64-4138-919b-3032569a71da	sha256:3bb7f18e12becd05e5b824040db0ea8a60ac7f1daef9d835242e3b94ce16cf7c	1047	/data/blobs/111/111/3bb7f18e12becd05e5b824040db0ea8a60ac7f1daef9d835242e3b94ce16cf7c.blob	application/octet-stream	\N	2026-04-27 09:58:57.164268+00	2026-04-27 09:58:57.164268+00	\N
4301355d-edc8-42ce-afa0-0ed5f465ce09	sha256:c00bb513a5531c9bee0ade0dd16cf0b651a2ed95b027dda1f014306c257a54f1	147	/data/blobs/ocloudhub/nginx-proxy-manager/c00bb513a5531c9bee0ade0dd16cf0b651a2ed95b027dda1f014306c257a54f1.blob	application/octet-stream	\N	2026-04-28 22:11:59.955899+00	2026-04-28 22:11:59.955899+00	\N
3e646a74-e5c1-42d4-b44c-15a1897c2da5	sha256:3307ff62622555b12f30e1312abd905eb208c57acf499a92196d2a1f9de51808	244067	/data/blobs/ocloudhub/nginx-proxy-manager/3307ff62622555b12f30e1312abd905eb208c57acf499a92196d2a1f9de51808.blob	application/octet-stream	\N	2026-04-28 22:12:00.056234+00	2026-04-28 22:12:00.056234+00	\N
9a6df382-d758-457a-b056-df76bab2304e	sha256:7db33d441f2e98470a3dbfbdcba4d403418f0e6629015d530c7f3c0a7bc856a1	456	/data/blobs/ocloudhub/nginx-proxy-manager/7db33d441f2e98470a3dbfbdcba4d403418f0e6629015d530c7f3c0a7bc856a1.blob	application/octet-stream	\N	2026-04-28 22:12:00.066139+00	2026-04-28 22:12:00.066139+00	\N
aba6885c-a4b3-49ae-9fab-a11baf751219	sha256:eb5112377e547f98416521c74005e693717821664887a91de480e6ac11e8bf33	360	/data/blobs/ocloudhub/nginx-proxy-manager/eb5112377e547f98416521c74005e693717821664887a91de480e6ac11e8bf33.blob	application/octet-stream	\N	2026-04-28 22:12:00.142322+00	2026-04-28 22:12:00.142322+00	\N
aa3436f7-f252-4759-9e6c-e96e5f43cb45	sha256:61a2e42c84dcf8e4f23cd3bc2ae37a4cb691271b584bece61a363dc5fab8b931	651596	/data/blobs/ocloudhub/nginx-proxy-manager/61a2e42c84dcf8e4f23cd3bc2ae37a4cb691271b584bece61a363dc5fab8b931.blob	application/octet-stream	\N	2026-04-28 22:12:00.19775+00	2026-04-28 22:12:00.19775+00	\N
5b69f297-e6ae-4723-b629-2fa1f9445bce	sha256:1bae921eab541b5ccbd880d1ac242d1f90a7d8fb83ce332c474a40eadf3fe97a	679	/data/blobs/ocloudhub/nginx-proxy-manager/1bae921eab541b5ccbd880d1ac242d1f90a7d8fb83ce332c474a40eadf3fe97a.blob	application/octet-stream	\N	2026-04-28 22:12:00.330244+00	2026-04-28 22:12:00.330244+00	\N
63dc206e-3322-41c0-8e98-8c7985bf0eb3	sha256:54692994e23f8fac2ff5336a8bdf33bef57638f028e8e904d3e392e28c3bc18a	402	/data/blobs/ocloudhub/nginx-proxy-manager/54692994e23f8fac2ff5336a8bdf33bef57638f028e8e904d3e392e28c3bc18a.blob	application/octet-stream	\N	2026-04-28 22:12:00.409561+00	2026-04-28 22:12:00.409561+00	\N
38a0f403-5f57-4bf8-9933-620a926df051	sha256:a634b2e12ab846e033c996b37c4f448bef821a5d6e4b877826f18adfd45ac91c	183	/data/blobs/ocloudhub/nginx-proxy-manager/a634b2e12ab846e033c996b37c4f448bef821a5d6e4b877826f18adfd45ac91c.blob	application/octet-stream	\N	2026-04-28 22:12:00.501687+00	2026-04-28 22:12:00.501687+00	\N
766e65c9-ba05-4ce8-b576-6d4f0d05c3d8	sha256:a720422b59c3de0223a4a45630c1b0f9778e3816881671623299fab082fded09	624	/data/blobs/ocloudhub/nginx-proxy-manager/a720422b59c3de0223a4a45630c1b0f9778e3816881671623299fab082fded09.blob	application/octet-stream	\N	2026-04-28 22:12:00.559172+00	2026-04-28 22:12:00.559172+00	\N
f54b50eb-01d7-499a-b826-59b78e5e9d65	sha256:05097c31b6341b57a6adf40a9a8fbeb3b8e89e8f92d16c7a8917eaaa21abdea5	1251927	/data/blobs/ocloudhub/nginx-proxy-manager/05097c31b6341b57a6adf40a9a8fbeb3b8e89e8f92d16c7a8917eaaa21abdea5.blob	application/octet-stream	\N	2026-04-28 22:12:00.862743+00	2026-04-28 22:12:00.862743+00	\N
f0f22321-cef0-4abb-8126-b182a94542f8	sha256:80938891139033cc39f92bb48ca95859d88e0df5fdb3bb109a4dbb7aa206ac62	476	/data/blobs/ocloudhub/nginx-proxy-manager/80938891139033cc39f92bb48ca95859d88e0df5fdb3bb109a4dbb7aa206ac62.blob	application/octet-stream	\N	2026-04-28 22:12:01.038741+00	2026-04-28 22:12:01.038741+00	\N
60e518a7-479e-4f0a-82f4-203ddc4d316e	sha256:45eac12aa2b67d87410e043a8bb1b97c5e1650e28f7eece5b069621e9d8470f0	14878016	/data/blobs/ocloudhub/nginx-proxy-manager/45eac12aa2b67d87410e043a8bb1b97c5e1650e28f7eece5b069621e9d8470f0.blob	application/octet-stream	\N	2026-04-28 22:12:03.354266+00	2026-04-28 22:12:03.354266+00	\N
a2fcf0b8-ec53-414d-88fa-e3d4520e566f	sha256:acd4e60e893d08cf989f888fc0c48aaac96f588e44c896164df37b432a72219f	15450643	/data/blobs/ocloudhub/nginx-proxy-manager/acd4e60e893d08cf989f888fc0c48aaac96f588e44c896164df37b432a72219f.blob	application/octet-stream	\N	2026-04-28 22:12:03.678105+00	2026-04-28 22:12:03.678105+00	\N
3b275b18-ec60-4de3-8651-513082e6bf53	sha256:359ef551bc898d4947cae71909129bed4803e87dd7d6137b4b9d02bec2156239	194	/data/blobs/ocloudhub/nginx-proxy-manager/359ef551bc898d4947cae71909129bed4803e87dd7d6137b4b9d02bec2156239.blob	application/octet-stream	\N	2026-04-28 22:12:03.968906+00	2026-04-28 22:12:03.968906+00	\N
cd98619c-f828-480c-a522-9377355905a6	sha256:da9512faf5a9eb00543d67c8729f63b519da0f559306a006fc8353cb1d249dca	5788602	/data/blobs/ocloudhub/nginx-proxy-manager/da9512faf5a9eb00543d67c8729f63b519da0f559306a006fc8353cb1d249dca.blob	application/octet-stream	\N	2026-04-28 22:12:04.624658+00	2026-04-28 22:12:04.624658+00	\N
81e5cc69-4fcf-4f7a-93df-01cb5dd5d94d	sha256:8708191564b59d9faacc07bfe98fc405f7b437fcd5cdee4b940559b3c9e3b03b	486	/data/blobs/ocloudhub/nginx-proxy-manager/8708191564b59d9faacc07bfe98fc405f7b437fcd5cdee4b940559b3c9e3b03b.blob	application/octet-stream	\N	2026-04-28 22:12:04.744077+00	2026-04-28 22:12:04.744077+00	\N
e8290690-18c2-457d-b4cc-b5230528a480	sha256:8ad438bd9dc71c27d7038e02ae05e98c9fa32aa792d1e52aa73b4bdb790c461b	356	/data/blobs/ocloudhub/nginx-proxy-manager/8ad438bd9dc71c27d7038e02ae05e98c9fa32aa792d1e52aa73b4bdb790c461b.blob	application/octet-stream	\N	2026-04-28 22:12:04.983088+00	2026-04-28 22:12:04.983088+00	\N
63158bed-64bd-497c-9011-e19ce9f91e67	sha256:676e6078c7a4f7ad855bc1a5f114fa4c9ff37d5e1a1a6ade5556803633260288	128	/data/blobs/ocloudhub/nginx-proxy-manager/676e6078c7a4f7ad855bc1a5f114fa4c9ff37d5e1a1a6ade5556803633260288.blob	application/octet-stream	\N	2026-04-28 22:12:05.119775+00	2026-04-28 22:12:05.119775+00	\N
feb9a549-214e-4f9d-b0b0-471928119b38	sha256:866fc0eade87f5597cc70dc9674f0819ad6e08d886516521133c6635996beb01	279807	/data/blobs/ocloudhub/nginx-proxy-manager/866fc0eade87f5597cc70dc9674f0819ad6e08d886516521133c6635996beb01.blob	application/octet-stream	\N	2026-04-28 22:12:05.357951+00	2026-04-28 22:12:05.357951+00	\N
6c5627ff-6e82-4479-a3ff-c686d188b430	sha256:702b64da8a8518ab37d3ca03389ce20594edab975047b9e5ff89fb97df482aab	650	/data/blobs/ocloudhub/nginx-proxy-manager/702b64da8a8518ab37d3ca03389ce20594edab975047b9e5ff89fb97df482aab.blob	application/octet-stream	\N	2026-04-28 22:12:05.479379+00	2026-04-28 22:12:05.479379+00	\N
1443abfe-12dc-4179-9eef-241db22628a9	sha256:302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab	29126276	/data/blobs/ocloudhub/nginx-proxy-manager/302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab.blob	application/octet-stream	\N	2026-04-28 22:12:05.622231+00	2026-04-28 22:12:05.622231+00	\N
0c6e1c12-7148-4359-b906-e6bd42d989f1	sha256:23219b0c28a3bba4abae4ae552ec39e140b50236a78af411b48443d53caa10d2	136026	/data/blobs/ocloudhub/nginx-proxy-manager/23219b0c28a3bba4abae4ae552ec39e140b50236a78af411b48443d53caa10d2.blob	application/octet-stream	\N	2026-04-28 22:12:05.933097+00	2026-04-28 22:12:05.933097+00	\N
ea5b8abd-b3ef-43b2-8b99-02331790f9b9	sha256:8f5c9ca23caa3bba4444876eb420114546eaca51d41a7c405d2dad20c94ac959	2230461	/data/blobs/ocloudhub/nginx-proxy-manager/8f5c9ca23caa3bba4444876eb420114546eaca51d41a7c405d2dad20c94ac959.blob	application/octet-stream	\N	2026-04-28 22:12:06.088228+00	2026-04-28 22:12:06.088228+00	\N
587e09c0-ee5b-4900-9455-f81db7f94178	sha256:84c774d6fc02c92d4215c06bb16d573000b5c47adb80be0f62c60740bfb133cb	5618	/data/blobs/ocloudhub/nginx-proxy-manager/84c774d6fc02c92d4215c06bb16d573000b5c47adb80be0f62c60740bfb133cb.blob	application/octet-stream	\N	2026-04-28 22:12:06.341154+00	2026-04-28 22:12:06.341154+00	\N
19b5e484-16df-46b4-9571-ce7bc8aaa979	sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1	32	/data/blobs/ocloudhub/nginx-proxy-manager/4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1.blob	application/octet-stream	\N	2026-04-28 22:12:06.457087+00	2026-04-28 22:12:06.457087+00	\N
1e2f42a9-2bf9-4bb2-b46c-341699c9235a	sha256:0916526bb1003f0eda2d08fffda33c2b8bf31736c10265398ca163d4e07d0050	2372406	/data/blobs/ocloudhub/nginx-proxy-manager/0916526bb1003f0eda2d08fffda33c2b8bf31736c10265398ca163d4e07d0050.blob	application/octet-stream	\N	2026-04-28 22:12:06.523024+00	2026-04-28 22:12:06.523024+00	\N
94355afa-9cf7-490c-896c-96bc58bafbca	sha256:7af29f242c7f5bb1d63185e56fb38b07ff675dc2fa9c60d53fe5aa19fdcd3b39	10610	/data/blobs/ocloudhub/nginx-proxy-manager/7af29f242c7f5bb1d63185e56fb38b07ff675dc2fa9c60d53fe5aa19fdcd3b39.blob	application/octet-stream	\N	2026-04-28 22:12:06.771977+00	2026-04-28 22:12:06.771977+00	\N
840ccbd6-5102-49a3-8b5c-08ed94192d3c	sha256:179fffe916b186867348c5ef2c279d32afff8d1b891c9a7e51d770e5f4228549	35674483	/data/blobs/ocloudhub/nginx-proxy-manager/179fffe916b186867348c5ef2c279d32afff8d1b891c9a7e51d770e5f4228549.blob	application/octet-stream	\N	2026-04-28 22:12:06.790262+00	2026-04-28 22:12:06.790262+00	\N
90beeaa4-e492-45d8-b7d0-5f66fce04ffc	sha256:095ae9c71c6b2b1966360f84bffc4ac074f7b9ce71b2f2561984aed73917c9cb	700	/data/blobs/ocloudhub/nginx-proxy-manager/095ae9c71c6b2b1966360f84bffc4ac074f7b9ce71b2f2561984aed73917c9cb.blob	application/octet-stream	\N	2026-04-28 22:12:06.930874+00	2026-04-28 22:12:06.930874+00	\N
a256765f-3955-4e90-96dd-87b6a3d072e2	sha256:73bd3ceed50be16c57e6cadfb066a75652ece3fb0d8ca5ab29f0c7ce5c5929f5	1066	/data/blobs/ocloudhub/nginx-proxy-manager/73bd3ceed50be16c57e6cadfb066a75652ece3fb0d8ca5ab29f0c7ce5c5929f5.blob	application/octet-stream	\N	2026-04-28 22:12:06.942343+00	2026-04-28 22:12:06.942343+00	\N
b469d228-1c10-4fe6-8a66-5fabd51651bd	sha256:a13b4e36ee19b60e1d1dd7bcbbc928ea03b81e47e78abf13c963db498395c83d	203	/data/blobs/ocloudhub/nginx-proxy-manager/a13b4e36ee19b60e1d1dd7bcbbc928ea03b81e47e78abf13c963db498395c83d.blob	application/octet-stream	\N	2026-04-28 22:12:07.089243+00	2026-04-28 22:12:07.089243+00	\N
d2896bb8-58e3-462b-9600-d9f255c9dfc0	sha256:a73af32908456ebfda8ae9d9cb0fd84399eaa29ce132d2f108eca5906ed7c5a6	373	/data/blobs/11111/2222/a73af32908456ebfda8ae9d9cb0fd84399eaa29ce132d2f108eca5906ed7c5a6.blob	application/json	\N	2026-04-29 01:51:32.533517+00	2026-04-29 01:51:32.533517+00	\N
aec14217-4a44-4ae9-b2c3-3ae10a7ac711	sha256:99cdc4818f6f536602b51581a85377099c0ec19b1015c6d6f5d05a005caf96e2	275	/data/blobs/ocloudhub/nginx-proxy-manager/99cdc4818f6f536602b51581a85377099c0ec19b1015c6d6f5d05a005caf96e2.blob	application/octet-stream	\N	2026-04-28 22:12:07.101544+00	2026-04-28 22:12:07.101544+00	\N
f4683be0-03a1-49b2-9b7a-8556ef717de0	sha256:6c4f963da65b87106f2cfe43345e87f84342cd3fe3be36d4cb782e0bf58f6e98	32109078	/data/blobs/ocloudhub/nginx-proxy-manager/6c4f963da65b87106f2cfe43345e87f84342cd3fe3be36d4cb782e0bf58f6e98.blob	application/octet-stream	\N	2026-04-28 22:12:07.202692+00	2026-04-28 22:12:07.202692+00	\N
92f19182-6cdb-48df-bece-6dee0e77273b	sha256:c2d93cccfe6da16140779f44dfbb92295bc4574202c7727b95c56f591b3dead3	799	/data/blobs/ocloudhub/nginx-proxy-manager/c2d93cccfe6da16140779f44dfbb92295bc4574202c7727b95c56f591b3dead3.blob	application/octet-stream	\N	2026-04-28 22:12:07.263043+00	2026-04-28 22:12:07.263043+00	\N
4226b413-3362-4bad-bd21-488308579085	sha256:6bf784b182fce7e43f96c31d8d74415cee58e40b5888c2d45f5edfde9542830a	2382053	/data/blobs/ocloudhub/nginx-proxy-manager/6bf784b182fce7e43f96c31d8d74415cee58e40b5888c2d45f5edfde9542830a.blob	application/octet-stream	\N	2026-04-28 22:12:07.818535+00	2026-04-28 22:12:07.818535+00	\N
a706527b-a237-4915-b266-41b57855cb6b	sha256:d4ea5225b70d94003fdb687565c671cfece850b1ef78eeb49df3e07ad69121f0	46569610	/data/blobs/ocloudhub/nginx-proxy-manager/d4ea5225b70d94003fdb687565c671cfece850b1ef78eeb49df3e07ad69121f0.blob	application/octet-stream	\N	2026-04-28 22:12:09.226196+00	2026-04-28 22:12:09.226196+00	\N
13ce6ecb-5f8c-471f-aaf5-a25314ed1a95	sha256:c37237caf2c6000e0ee287b028651e3a19f5780a29af1039e3f9f2af8f0eb095	13928086	/data/blobs/ocloudhub/nginx-proxy-manager/c37237caf2c6000e0ee287b028651e3a19f5780a29af1039e3f9f2af8f0eb095.blob	application/octet-stream	\N	2026-04-28 22:12:09.490035+00	2026-04-28 22:12:09.490035+00	\N
d3412e8b-d186-4112-9436-5f5f8f66492d	sha256:e2483c4dd0c6c8125fcbaa645ab8b60ba46c6395b5d75ebc44956cf087f37a62	172776215	/data/blobs/ocloudhub/nginx-proxy-manager/e2483c4dd0c6c8125fcbaa645ab8b60ba46c6395b5d75ebc44956cf087f37a62.blob	application/octet-stream	\N	2026-04-28 22:12:37.334763+00	2026-04-28 22:12:37.334763+00	\N
5eb549d1-89ad-46ab-bb72-632e40bd48ed	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	20102	/data/blobs/ocloudhub/nginx-proxy-manager/e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741.blob	application/octet-stream	\N	2026-04-28 22:12:37.396982+00	2026-04-28 22:12:37.396982+00	\N
44161cbd-281b-4e2d-b6fe-5d9355b97f54	sha256:cf0656a5b13bedc4a1707ececdc7c6186e8178310687a14e83ee6f87715fb65c	404	/data/blobs/111/111/cf0656a5b13bedc4a1707ececdc7c6186e8178310687a14e83ee6f87715fb65c.blob	application/json	\N	2026-04-29 01:47:28.400369+00	2026-04-29 01:47:28.400369+00	\N
ef6f3b4d-4470-4ed3-9d11-b9e17d9b180e	sha256:8ea340c2c5addaefde4f37360e917731dc1610e4b0c424598e57c6c2c95f015c	482	/data/blobs/111/111/8ea340c2c5addaefde4f37360e917731dc1610e4b0c424598e57c6c2c95f015c.blob	application/octet-stream	\N	2026-04-29 01:47:28.411568+00	2026-04-29 01:47:28.411568+00	\N
a552d730-4b10-4e77-87c0-9975234f5996	sha256:c4f9743e910169563769da2e07bf10a78fb4c9b0c489a2ee2c1f8bb25dc5bac6	1884672	/data/blobs/111/111/c4f9743e910169563769da2e07bf10a78fb4c9b0c489a2ee2c1f8bb25dc5bac6.blob	application/octet-stream	\N	2026-04-29 01:47:28.420684+00	2026-04-29 01:47:28.420684+00	\N
c7851e56-f0dc-4be8-a71f-e8fa30a4ed79	sha256:d37092179ddccad1ee0b97d96b129b58f41d5acc765698bf3b972896347f3d84	216064	/data/blobs/111/111/d37092179ddccad1ee0b97d96b129b58f41d5acc765698bf3b972896347f3d84.blob	application/octet-stream	\N	2026-04-29 01:47:28.428345+00	2026-04-29 01:47:28.428345+00	\N
b23bedcb-d371-4537-94d2-b82ad8a0a9d4	sha256:f73d79df02061d527bd003fe9b66a539cc95f76ca3a127c4248d7cf17c527dd1	482	/data/blobs/111/111/f73d79df02061d527bd003fe9b66a539cc95f76ca3a127c4248d7cf17c527dd1.blob	application/octet-stream	\N	2026-04-29 01:47:28.440475+00	2026-04-29 01:47:28.440475+00	\N
df2d9f0a-5dae-477c-a9ba-d62b8e1aeaf5	sha256:88e53e46c4d2bed466a6b02167ef9d8cef2c9392c4ee9fb64f7a0e7c38c31858	3544576	/data/blobs/111/111/88e53e46c4d2bed466a6b02167ef9d8cef2c9392c4ee9fb64f7a0e7c38c31858.blob	application/octet-stream	\N	2026-04-29 01:47:28.461421+00	2026-04-29 01:47:28.461421+00	\N
5b4c267d-9e50-44ce-b171-4609de0cb9a9	sha256:039e7f926bd177ed09068bb9ce404d38b669aba7cc98ff324194dde7cb318976	406	/data/blobs/111/111/039e7f926bd177ed09068bb9ce404d38b669aba7cc98ff324194dde7cb318976.blob	application/octet-stream	\N	2026-04-29 01:47:28.471544+00	2026-04-29 01:47:28.471544+00	\N
b52a3df9-8d67-40c2-b3b3-3ad56e49c36b	sha256:48a0959ec57746c5b54d3f0ee68ba154defefab5c979c49d4afa78e2a183303f	3584	/data/blobs/111/111/48a0959ec57746c5b54d3f0ee68ba154defefab5c979c49d4afa78e2a183303f.blob	application/octet-stream	\N	2026-04-29 01:47:28.47396+00	2026-04-29 01:47:28.47396+00	\N
3dccb04e-ada9-4f12-9357-adaa9619e043	sha256:51f90edb8e4f7e7e056ea87676345469144de63d7616bfe6aff1f4d9a10d76be	482	/data/blobs/111/111/51f90edb8e4f7e7e056ea87676345469144de63d7616bfe6aff1f4d9a10d76be.blob	application/octet-stream	\N	2026-04-29 01:47:28.476266+00	2026-04-29 01:47:28.476266+00	\N
238312b1-ade5-4b90-98ac-48c3817d6b06	sha256:65df1de0fc5d5ed3b009724450521360e9cac82bb7a18c2565705224e5d966be	110994432	/data/blobs/111/111/65df1de0fc5d5ed3b009724450521360e9cac82bb7a18c2565705224e5d966be.blob	application/octet-stream	\N	2026-04-29 01:47:29.165313+00	2026-04-29 01:47:29.165313+00	\N
18da9e1f-28c7-4084-af9d-eef671b6ed90	sha256:6e4622138e7123a662eb8da39c3da85d1605d7a9a0749b8939b3b22b3d14a1d5	5506048	/data/blobs/111/111/6e4622138e7123a662eb8da39c3da85d1605d7a9a0749b8939b3b22b3d14a1d5.blob	application/octet-stream	\N	2026-04-29 01:47:29.561209+00	2026-04-29 01:47:29.561209+00	\N
d4e10834-5448-4b17-b64f-de7fbbba04ea	sha256:702bea3dc94887d2fcf1aa0d56565c57d5ca6d24659c8d0b6cbde5c58d6c182f	23511040	/data/blobs/111/111/702bea3dc94887d2fcf1aa0d56565c57d5ca6d24659c8d0b6cbde5c58d6c182f.blob	application/octet-stream	\N	2026-04-29 01:47:29.726868+00	2026-04-29 01:47:29.726868+00	\N
2b8b5e97-4626-40de-a9a8-0bf72600e87f	sha256:adcb98b70e5c8d82803fa2409d184a1acd422281c8f8a3d56d2819d4f9873da3	482	/data/blobs/111/111/adcb98b70e5c8d82803fa2409d184a1acd422281c8f8a3d56d2819d4f9873da3.blob	application/octet-stream	\N	2026-04-29 01:47:30.01471+00	2026-04-29 01:47:30.01471+00	\N
ecf42bbd-6c21-431a-baf6-fe3130a6df6f	sha256:df84c61fd4b4c14881409253ba5a12bb974d5aa82cab917d5ef374f1c475ae01	482	/data/blobs/111/111/df84c61fd4b4c14881409253ba5a12bb974d5aa82cab917d5ef374f1c475ae01.blob	application/octet-stream	\N	2026-04-29 01:47:30.049413+00	2026-04-29 01:47:30.049413+00	\N
a175ac8f-7253-44b3-b1d8-2a942922ba89	sha256:69b2ec208575b69597784255eec6fa6a2985ee9e1a47f4411a51f7f5fdd193a9	8506	/data/blobs/111/111/69b2ec208575b69597784255eec6fa6a2985ee9e1a47f4411a51f7f5fdd193a9.blob	application/octet-stream	\N	2026-04-29 01:47:30.052826+00	2026-04-29 01:47:30.052826+00	\N
3f243f13-f6fb-4f5f-90a3-08130581e63c	sha256:a16cad481969d7ddb6fcd2f1c58284af3d1266190b9bedc3ef0801aeb05a93a9	1623	/data/blobs/111/111/a16cad481969d7ddb6fcd2f1c58284af3d1266190b9bedc3ef0801aeb05a93a9.blob	application/octet-stream	\N	2026-04-29 01:47:30.056117+00	2026-04-29 01:47:30.056117+00	\N
b477e190-06d0-4685-868b-39c6ba5dda12	sha256:b42e10051e241ae55e28b0602b0f6fdc8a55938f04562a21a2bdaca9fcba93db	482	/data/blobs/111/111/b42e10051e241ae55e28b0602b0f6fdc8a55938f04562a21a2bdaca9fcba93db.blob	application/octet-stream	\N	2026-04-29 01:47:30.058549+00	2026-04-29 01:47:30.058549+00	\N
388357b7-e158-452e-8ab1-3c26f018baea	sha256:ca8e71a88f9b1ce7a46d527ef22fcbc8919d27b063736be06e0cbc978328d6df	2449	/data/blobs/111/111/ca8e71a88f9b1ce7a46d527ef22fcbc8919d27b063736be06e0cbc978328d6df.blob	application/octet-stream	\N	2026-04-29 01:47:30.061395+00	2026-04-29 01:47:30.061395+00	\N
5523075d-3678-4227-9fa6-8921fe922b83	sha256:d9e4fbf4fcf5a2a873b09a4f801d1576be6ef9acfc4d712e4bb010fe323a98bc	30540800	/data/blobs/111/111/d9e4fbf4fcf5a2a873b09a4f801d1576be6ef9acfc4d712e4bb010fe323a98bc.blob	application/octet-stream	\N	2026-04-29 01:47:30.330139+00	2026-04-29 01:47:30.330139+00	\N
7855ce28-fe45-46de-a349-c7a117b40c9f	sha256:469babe0725a8ef9ea8ee85eed6e55dc33682ff9ba4fc4b61e4434e0ac1e447b	36864	/data/blobs/111/111/469babe0725a8ef9ea8ee85eed6e55dc33682ff9ba4fc4b61e4434e0ac1e447b.blob	application/octet-stream	\N	2026-04-29 01:47:30.407917+00	2026-04-29 01:47:30.407917+00	\N
d91184ca-1bb3-4f07-b8b5-1bb12bb85cb9	sha256:082cd4b1e7a6940469025c6f08cb87553ff57077b1a597aaafbf9a5be34146b5	482	/data/blobs/111/111/082cd4b1e7a6940469025c6f08cb87553ff57077b1a597aaafbf9a5be34146b5.blob	application/octet-stream	\N	2026-04-29 01:47:30.41492+00	2026-04-29 01:47:30.41492+00	\N
8c40f793-5404-4725-b76c-3885ab266c91	sha256:db7917b5c078625227b308eb2181f42252c7932cc5ae09c3c700c2c83e3e9bd3	482	/data/blobs/11111/2222/db7917b5c078625227b308eb2181f42252c7932cc5ae09c3c700c2c83e3e9bd3.blob	application/octet-stream	\N	2026-04-29 01:51:32.537522+00	2026-04-29 01:51:32.537522+00	\N
6b376cfe-149e-44d0-88ef-3dbc77b5fdbe	sha256:f450912a49ae90d90f716be935b01d1398feb0bc27ea7db54598847ffdcd1e87	3072	/data/blobs/11111/2222/f450912a49ae90d90f716be935b01d1398feb0bc27ea7db54598847ffdcd1e87.blob	application/octet-stream	\N	2026-04-29 01:51:32.54138+00	2026-04-29 01:51:32.54138+00	\N
69f6b40e-d397-44dc-b43b-754fd5b9e4b6	sha256:29d935845523d9ab4d6c0f05fc9f458c9586fba08be6811412744e6a4d4cc2b0	6856	/data/blobs/11111/2222/29d935845523d9ab4d6c0f05fc9f458c9586fba08be6811412744e6a4d4cc2b0.blob	application/octet-stream	\N	2026-04-29 01:51:32.543311+00	2026-04-29 01:51:32.543311+00	\N
683f4fab-d0f8-4360-b17a-aba42d3ce169	sha256:4a2a905e95ce989380bce79071b4d3b23e910b206a13644d106c5854096f0f93	406	/data/blobs/11111/2222/4a2a905e95ce989380bce79071b4d3b23e910b206a13644d106c5854096f0f93.blob	application/octet-stream	\N	2026-04-29 01:51:32.546037+00	2026-04-29 01:51:32.546037+00	\N
0a870216-803d-4018-80b0-638c49ec6311	sha256:4f9886536aec8164ee5ad8dc1556b714181041b0cd4763cba48a8466ca7349ee	1336	/data/blobs/11111/2222/4f9886536aec8164ee5ad8dc1556b714181041b0cd4763cba48a8466ca7349ee.blob	application/octet-stream	\N	2026-04-29 01:51:32.548844+00	2026-04-29 01:51:32.548844+00	\N
e049bca0-e342-4034-8096-1712d233ed9c	sha256:d79fa63a1e8b608000703fcb6642e76314aee640314a3499ece7ed497768a3de	1877504	/data/blobs/11111/2222/d79fa63a1e8b608000703fcb6642e76314aee640314a3499ece7ed497768a3de.blob	application/octet-stream	\N	2026-04-29 01:51:32.552611+00	2026-04-29 01:51:32.552611+00	\N
b55183c0-8343-4123-a628-43ff4c8d97e3	sha256:37160e49a8ba9e427a89d360dd01a7f64137b90d5cb43f0f66e5ceeb7696a9a9	451	11111/2222/37160e49a8ba9e427a89d360dd01a7f64137b90d5cb43f0f66e5ceeb7696a9a9.blob	application/octet-stream	\N	2026-04-30 01:13:53.24284+00	2026-04-30 01:13:53.24284+00	\N
d24726fc-6416-4a3d-9577-c0a84f49b05b	sha256:994456c4fd7b2b87346a81961efb4ce945a39592d32e0762b38768bca7c7d085	8088576	/data/blobs/11111/2222/994456c4fd7b2b87346a81961efb4ce945a39592d32e0762b38768bca7c7d085.blob	application/octet-stream	\N	2026-04-29 01:51:32.562055+00	2026-04-29 01:51:32.562055+00	\N
e731bab7-d093-4962-a7ab-c7bb7e4abf65	sha256:bc52c372987c498f29f7e2229bd49e4f5a69b7e3c917ff509ef79327d737ec38	704	/data/blobs/11111/2222/bc52c372987c498f29f7e2229bd49e4f5a69b7e3c917ff509ef79327d737ec38.blob	application/octet-stream	\N	2026-04-29 01:51:32.564196+00	2026-04-29 01:51:32.564196+00	\N
0a981a97-0fcc-44fc-999c-80e53787b1a3	sha256:76fa31fed878a83df79e28eb997389794f769ef8388c4c5a0c3ebf10134495ed	1390128	11111/2222/76fa31fed878a83df79e28eb997389794f769ef8388c4c5a0c3ebf10134495ed.blob	application/octet-stream	\N	2026-04-30 01:13:53.731862+00	2026-04-30 01:13:53.731862+00	\N
c800520c-c51b-41df-ac0e-a83d3e14762d	sha256:25f5c574f7c42af0ca59afc447854c6e0cd2372a1648201dbfeb6dbd12a8f388	2367172	11111/2222/25f5c574f7c42af0ca59afc447854c6e0cd2372a1648201dbfeb6dbd12a8f388.blob	application/octet-stream	\N	2026-04-30 01:13:53.807006+00	2026-04-30 01:13:53.807006+00	\N
3d6f407b-e142-471b-95ea-52d63cdf4ea5	sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8	3408729	11111/2222/4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8.blob	application/octet-stream	\N	2026-04-30 01:13:53.920753+00	2026-04-30 01:13:53.920753+00	\N
01cfb0ef-770f-4782-a3bc-beb7afe132da	sha256:915c0dd581c62180404aa1bbc3194060b12b8998bcd05a21a5bc90045e567192	26402531	11111/2222/915c0dd581c62180404aa1bbc3194060b12b8998bcd05a21a5bc90045e567192.blob	application/octet-stream	\N	2026-04-30 01:13:59.418495+00	2026-04-30 01:13:59.418495+00	\N
72ea0dd9-d083-4308-85a3-6e1cc8d47e4c	sha256:1c6d0e08288a024c214843513c59066d32e7fa44f51c42fdf2135e14c3325e59	43942648	11111/2222/1c6d0e08288a024c214843513c59066d32e7fa44f51c42fdf2135e14c3325e59.blob	application/octet-stream	\N	2026-04-30 01:14:01.596789+00	2026-04-30 01:14:01.596789+00	\N
77a8f17e-e272-4efb-a01a-7006d75d790f	sha256:be74271b82ab93337f1e31abbdfa713d0850a511f6ae1488e137b1662d4fe432	77253337	11111/2222/be74271b82ab93337f1e31abbdfa713d0850a511f6ae1488e137b1662d4fe432.blob	application/octet-stream	\N	2026-04-30 01:14:08.300131+00	2026-04-30 01:14:08.300131+00	\N
434452a6-06c2-4afe-b05e-3dce528dae4f	sha256:499b951337574fb4ac911fc38a061589c14b501ebc4b10da144ed9144e2ec402	7641	11111/2222/499b951337574fb4ac911fc38a061589c14b501ebc4b10da144ed9144e2ec402.blob	application/octet-stream	\N	2026-04-30 01:14:08.335986+00	2026-04-30 01:14:08.335986+00	\N
142deee4-e28e-4fa1-8bce-f2704617ec22	sha256:1165b869c51a1a0747d78cec8fab96c30156a979e51ecf2f91aa792e557d94a4	20250706	11111/2222/1165b869c51a1a0747d78cec8fab96c30156a979e51ecf2f91aa792e557d94a4.blob	application/octet-stream	\N	2026-05-06 10:58:25.424156+00	2026-05-06 10:58:25.424156+00	\N
52954dde-536d-43e2-80b7-2f19a63fa0b6	sha256:5bd7bd52e5bcab15a093466b90e37472b0d0c0081052522afb8924cbdaf15f56	12323	11111/2222/5bd7bd52e5bcab15a093466b90e37472b0d0c0081052522afb8924cbdaf15f56.blob	application/octet-stream	\N	2026-05-06 10:58:28.927123+00	2026-05-06 10:58:28.927123+00	\N
ca7f675d-0d6c-4864-96e1-d3e65cc4606d	sha256:4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953	362	/data/blobs/11111/blob-test-2/4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953.blob	application/json	\N	2026-04-29 04:32:50.485688+00	2026-04-29 04:32:50.485688+00	\N
3629c989-1caf-4ed1-872b-a068b3f816ab	sha256:5d4427064ecc46e3c2add169e9b5eafc7ed2be7861081ec925938ab628ac0e25	77883904	/data/blobs/11111/blob-test-2/5d4427064ecc46e3c2add169e9b5eafc7ed2be7861081ec925938ab628ac0e25.blob	application/octet-stream	\N	2026-04-29 04:32:50.778173+00	2026-04-29 04:32:50.778173+00	\N
242bf72b-1533-4118-9131-f7566fae3971	sha256:747b290aeba888738176dcbf7382eb0f660f27e785b839592918b8ed291d5792	3584	/data/blobs/11111/blob-test-2/747b290aeba888738176dcbf7382eb0f660f27e785b839592918b8ed291d5792.blob	application/octet-stream	\N	2026-04-29 04:32:50.962661+00	2026-04-29 04:32:50.962661+00	\N
4d18d128-2934-47b8-b60f-a8a62ead66a2	sha256:7d2fd59c368c60f74214fc47399dcc35ef8513e26890a0c6004835bceabeb4c6	5120	/data/blobs/11111/blob-test-2/7d2fd59c368c60f74214fc47399dcc35ef8513e26890a0c6004835bceabeb4c6.blob	application/octet-stream	\N	2026-04-29 04:32:50.96883+00	2026-04-29 04:32:50.96883+00	\N
9bc5ee2b-8549-4764-8668-5413098a3839	sha256:fc1cf9ca5139883943cc519cc3c57f0855395618f56d6431490fa735461156f1	113876992	/data/blobs/11111/blob-test-2/fc1cf9ca5139883943cc519cc3c57f0855395618f56d6431490fa735461156f1.blob	application/octet-stream	\N	2026-04-29 04:32:51.086923+00	2026-04-29 04:32:51.086923+00	\N
b2b62b1c-e2f6-4ded-a96a-0e882403af08	sha256:0589da02acf7527eae32341b1fc1abb16e4f1fb9d93cb6f021633866d1fc21f3	482	/data/blobs/11111/blob-test-2/0589da02acf7527eae32341b1fc1abb16e4f1fb9d93cb6f021633866d1fc21f3.blob	application/octet-stream	\N	2026-04-29 04:32:51.263671+00	2026-04-29 04:32:51.263671+00	\N
3403e87a-2ce3-4222-afb2-6e7fb9e118f8	sha256:56f8fe6aedcdee31bdee17249b1e18434ce7ab5a1814e2193773b54d7f9db39a	2560	/data/blobs/11111/blob-test-2/56f8fe6aedcdee31bdee17249b1e18434ce7ab5a1814e2193773b54d7f9db39a.blob	application/octet-stream	\N	2026-04-29 04:32:51.268249+00	2026-04-29 04:32:51.268249+00	\N
bbea5731-0bfd-4833-a09d-6b54d4583bc5	sha256:b79678fc97993a6dcd358e7ab24b4e4f12ab171f491cc7148351099d7f723126	482	/data/blobs/11111/blob-test-2/b79678fc97993a6dcd358e7ab24b4e4f12ab171f491cc7148351099d7f723126.blob	application/octet-stream	\N	2026-04-29 04:32:51.271774+00	2026-04-29 04:32:51.271774+00	\N
784f6179-868f-44ad-a8ce-1788f776b7a1	sha256:6f36f02eb4350d3f5651ca3d965a3c9d36768ae6df218dd9f3994fb73de34832	406	/data/blobs/11111/blob-test-2/6f36f02eb4350d3f5651ca3d965a3c9d36768ae6df218dd9f3994fb73de34832.blob	application/octet-stream	\N	2026-04-29 04:32:51.275199+00	2026-04-29 04:32:51.275199+00	\N
9f40207a-b93f-48dd-838e-a3da7e7c2b8b	sha256:8dae4ea76cf104552e46a995f7eeb58df13a9ec09ea43c75f6b1b3e4f68197c0	482	/data/blobs/11111/blob-test-2/8dae4ea76cf104552e46a995f7eeb58df13a9ec09ea43c75f6b1b3e4f68197c0.blob	application/octet-stream	\N	2026-04-29 04:32:51.278219+00	2026-04-29 04:32:51.278219+00	\N
fd818ae6-c07b-4e16-9b29-b834c3bd5df1	sha256:98b73c33a9278287dac8a82be23a6bcba78e060e0188ff77bbbad0aa854e1c51	1118	/data/blobs/11111/blob-test-2/98b73c33a9278287dac8a82be23a6bcba78e060e0188ff77bbbad0aa854e1c51.blob	application/octet-stream	\N	2026-04-29 04:32:51.281192+00	2026-04-29 04:32:51.281192+00	\N
de7863d0-331c-4eee-928e-302088511c70	sha256:9f4d73e635f122031c04047f0e87fb224bef098a28700439bb4e72d0619aaad6	4608	/data/blobs/11111/blob-test-2/9f4d73e635f122031c04047f0e87fb224bef098a28700439bb4e72d0619aaad6.blob	application/octet-stream	\N	2026-04-29 04:32:51.284307+00	2026-04-29 04:32:51.284307+00	\N
cd57d97c-a90d-466b-86d7-62dc4ec8df12	sha256:e27d85e5c528bade2596e4b9b79f268d7b31822c253afdf1a63eae2ede988dcc	1307	/data/blobs/11111/blob-test-2/e27d85e5c528bade2596e4b9b79f268d7b31822c253afdf1a63eae2ede988dcc.blob	application/octet-stream	\N	2026-04-29 04:32:51.287475+00	2026-04-29 04:32:51.287475+00	\N
20f22a5a-b1da-4460-89c3-915b2a0bc0cf	sha256:e784f4560448b14a66f55c26e1b4dad2c2877cc73d001b7cd0b18e24a700a070	7155	/data/blobs/11111/blob-test-2/e784f4560448b14a66f55c26e1b4dad2c2877cc73d001b7cd0b18e24a700a070.blob	application/octet-stream	\N	2026-04-29 04:32:51.290133+00	2026-04-29 04:32:51.290133+00	\N
04261ada-c360-47b4-a175-61a45cb30006	sha256:14773070094ddc0debcea4f38f0daa7dd8116858387e0c238fa96ae8047bc07e	7168	/data/blobs/11111/blob-test-2/14773070094ddc0debcea4f38f0daa7dd8116858387e0c238fa96ae8047bc07e.blob	application/octet-stream	\N	2026-04-29 04:32:51.292673+00	2026-04-29 04:32:51.292673+00	\N
706c7371-4516-4328-b589-8aaa194996ea	sha256:614e77ac763086172c71ea4b9910b5805d49506e3db118a88669e681e99b41d7	482	/data/blobs/11111/blob-test-2/614e77ac763086172c71ea4b9910b5805d49506e3db118a88669e681e99b41d7.blob	application/octet-stream	\N	2026-04-29 04:32:51.295027+00	2026-04-29 04:32:51.295027+00	\N
7f41f7aa-8841-4c50-a728-53307cc24990	sha256:a71873b303e8d75170b7ced2725b01b3ae15ad76f0d4eef16a49335821b6a0ef	404	11111/2222/a71873b303e8d75170b7ced2725b01b3ae15ad76f0d4eef16a49335821b6a0ef.blob	application/octet-stream	\N	2026-05-06 10:57:31.861001+00	2026-05-06 10:57:31.861001+00	\N
44c0d423-bf87-49c8-ba50-d9234fd75772	sha256:85c7e9a25dec238bbb263c28c9045aa8fb35f1d79135dcc91fc433bd019e4379	482	/data/blobs/11111/blob-test-2/85c7e9a25dec238bbb263c28c9045aa8fb35f1d79135dcc91fc433bd019e4379.blob	application/octet-stream	\N	2026-04-29 04:32:51.299385+00	2026-04-29 04:32:51.299385+00	\N
13659691-a651-4095-8377-0e5fb0a7c690	sha256:34dfdd2ef1f920d0054dde2fc09ddc83ff8e71d05fadb79e2cab6e6234596f0a	1210	11111/2222/34dfdd2ef1f920d0054dde2fc09ddc83ff8e71d05fadb79e2cab6e6234596f0a.blob	application/octet-stream	\N	2026-05-06 10:57:37.029987+00	2026-05-06 10:57:37.029987+00	\N
c5a1be5d-ad99-4ccd-9cae-0f9df73e89e3	sha256:c8a2fa3a88d244a3f32dcbc9c1f7649c662661a28c624198ada43aa0b7598e7f	1398	11111/2222/c8a2fa3a88d244a3f32dcbc9c1f7649c662661a28c624198ada43aa0b7598e7f.blob	application/octet-stream	\N	2026-05-06 10:57:41.353461+00	2026-05-06 10:57:41.353461+00	\N
9f43bdb6-7cb9-4dcb-a54c-93f24824ca1f	sha256:15e759724ff67f262e38bb7c070af9d0b84f959f9b37fa966f68bf2f881a4b62	627	11111/2222/15e759724ff67f262e38bb7c070af9d0b84f959f9b37fa966f68bf2f881a4b62.blob	application/octet-stream	\N	2026-05-06 10:57:47.700552+00	2026-05-06 10:57:47.700552+00	\N
d3488ed6-767c-43a7-b969-a1c829384260	sha256:589002ba0eaed121a1dbf42f6648f29e5be55d5c8a6ee0f8eaa0285cc21ac153	3861821	11111/2222/589002ba0eaed121a1dbf42f6648f29e5be55d5c8a6ee0f8eaa0285cc21ac153.blob	application/octet-stream	\N	2026-05-06 10:57:54.833891+00	2026-05-06 10:57:54.833891+00	\N
1095f9c9-e9e3-4567-a56a-944d16e3abe4	sha256:f03becc8ac15611cfcc421c977a5ba4d65456093570788523a4ba557689aa7f7	1870941	11111/2222/f03becc8ac15611cfcc421c977a5ba4d65456093570788523a4ba557689aa7f7.blob	application/octet-stream	\N	2026-05-06 10:57:57.418525+00	2026-05-06 10:57:57.418525+00	\N
19426863-37ee-4f89-9a4f-ead34e468ae9	sha256:ff9f59a6a62e9e9f29d7a84fb18865b45664d3f0d061eff7548bd61746dd101c	957	11111/2222/ff9f59a6a62e9e9f29d7a84fb18865b45664d3f0d061eff7548bd61746dd101c.blob	application/octet-stream	\N	2026-05-06 10:58:20.169772+00	2026-05-06 10:58:20.169772+00	\N
98d8d86b-3535-4cae-9cf8-91d88bcda4de	sha256:d7d7dbd2794ebb8af807c4592af3e0c88d0eca1d84472d23afb82f60e3fb1bed	356	/data/blobs/nginx/nginx/d7d7dbd2794ebb8af807c4592af3e0c88d0eca1d84472d23afb82f60e3fb1bed.blob	application/json	\N	2026-05-08 04:26:11.193569+00	2026-05-08 04:26:11.193569+00	\N
485bdb65-2907-4fb8-8241-2633c23828b1	sha256:08e80ad16a7ce67f85da3f1898b467bd4ca62adf5ad2ed771a01992557d1051d	4096	/data/blobs/nginx/nginx/08e80ad16a7ce67f85da3f1898b467bd4ca62adf5ad2ed771a01992557d1051d.blob	application/octet-stream	\N	2026-05-08 04:26:11.198281+00	2026-05-08 04:26:11.198281+00	\N
8d633990-4b9a-4177-94c9-16ceb4bd0549	sha256:abd35dd923f4b11531b3e239a3cd8b5732437bfa12e77e233f596a0bedbcfe84	406	/data/blobs/nginx/nginx/abd35dd923f4b11531b3e239a3cd8b5732437bfa12e77e233f596a0bedbcfe84.blob	application/octet-stream	\N	2026-05-08 04:26:11.201302+00	2026-05-08 04:26:11.201302+00	\N
7038e8a3-41eb-46d4-a566-3a9521a3392e	sha256:7705dd2858c100a95bba6140201b5c5315926c54d94a1577c6fa57876780d9ad	8723	/data/blobs/nginx/nginx/7705dd2858c100a95bba6140201b5c5315926c54d94a1577c6fa57876780d9ad.blob	application/octet-stream	\N	2026-05-08 04:26:11.204462+00	2026-05-08 04:26:11.204462+00	\N
57103e4f-a6ce-450a-a5d5-e28eab8adac6	sha256:a97119d466c39e6566334de076cf8cdd98069147412ed4857405de19905deaf0	482	/data/blobs/nginx/nginx/a97119d466c39e6566334de076cf8cdd98069147412ed4857405de19905deaf0.blob	application/octet-stream	\N	2026-05-08 04:26:11.207405+00	2026-05-08 04:26:11.207405+00	\N
cb785298-ec51-4b76-b972-27e45851fc15	sha256:b4fdcf5441ca8a388abf500ca2f7c836e8a6fe8d39d57b977dc798f67215e257	10752	/data/blobs/nginx/nginx/b4fdcf5441ca8a388abf500ca2f7c836e8a6fe8d39d57b977dc798f67215e257.blob	application/octet-stream	\N	2026-05-08 04:26:11.210544+00	2026-05-08 04:26:11.210544+00	\N
d449c9a4-0856-4d78-bd30-269d27e9471f	sha256:22512f75741800d54f96cdfdc9fa9c7ae739d1ceb8bfcdcd7c56e68da51057db	29836288	/data/blobs/nginx/nginx/22512f75741800d54f96cdfdc9fa9c7ae739d1ceb8bfcdcd7c56e68da51057db.blob	application/octet-stream	\N	2026-05-08 04:26:11.297972+00	2026-05-08 04:26:11.297972+00	\N
b3e49c47-9c63-48e3-a9ea-607b03ad8f02	sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef	1024	/data/blobs/nginx/nginx/5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef.blob	application/octet-stream	\N	2026-05-08 04:26:11.744581+00	2026-05-08 04:26:11.744581+00	\N
6e497b77-e94a-4441-9236-1a1c8c66b491	sha256:7b35df7e9eedc796b985f777439a05ce364fe1106118c8f68c27bc82f5863134	482	/data/blobs/nginx/nginx/7b35df7e9eedc796b985f777439a05ce364fe1106118c8f68c27bc82f5863134.blob	application/octet-stream	\N	2026-05-08 04:26:11.749552+00	2026-05-08 04:26:11.749552+00	\N
c77adf28-6975-4c6a-b0c1-30bcfb92a204	sha256:80f5e76237c08b06b53721a495e1e78c566345eeb4bb85cccacd873b0dd4d7c6	482	/data/blobs/nginx/nginx/80f5e76237c08b06b53721a495e1e78c566345eeb4bb85cccacd873b0dd4d7c6.blob	application/octet-stream	\N	2026-05-08 04:26:11.753431+00	2026-05-08 04:26:11.753431+00	\N
2cf44741-2ec4-4c91-9c22-0b5f837c1830	sha256:8e2ab394fabf557b00041a8f080b10b4e91c7027b7c174f095332c7ebb6501cb	77832192	/data/blobs/nginx/nginx/8e2ab394fabf557b00041a8f080b10b4e91c7027b7c174f095332c7ebb6501cb.blob	application/octet-stream	\N	2026-05-08 04:26:11.820866+00	2026-05-08 04:26:11.820866+00	\N
27af7544-d5eb-4a35-a8a6-b235ece338d2	sha256:d12bbeb2868d8012ad8493153963e345b0034ca6e6460d51981b395084879ab4	482	/data/blobs/nginx/nginx/d12bbeb2868d8012ad8493153963e345b0034ca6e6460d51981b395084879ab4.blob	application/octet-stream	\N	2026-05-08 04:26:11.83535+00	2026-05-08 04:26:11.83535+00	\N
11b87aee-223c-4395-98b3-7f241fb80ab6	sha256:5a934a3b40b02f2fbb6900c67970e0ebb87638cc93649d055230d2966d1599d4	1136	/data/blobs/nginx/nginx/5a934a3b40b02f2fbb6900c67970e0ebb87638cc93649d055230d2966d1599d4.blob	application/octet-stream	\N	2026-05-08 04:26:11.841435+00	2026-05-08 04:26:11.841435+00	\N
75154fc7-bae2-492b-bd66-ceee7e4a1ecd	sha256:57bd265ade4f3efe4c3896c36890204a362a1100fc0f2ab8f60c6f5bda931b39	4143104	/data/blobs/nginx/nginx/57bd265ade4f3efe4c3896c36890204a362a1100fc0f2ab8f60c6f5bda931b39.blob	application/octet-stream	\N	2026-05-08 04:26:11.847561+00	2026-05-08 04:26:11.847561+00	\N
d68d0ade-c161-4557-b993-7cdacef99f12	sha256:60c53808e755b183b87952b6e7b9f42323f4147ef1c59d5131ef3f758869e989	482	/data/blobs/nginx/nginx/60c53808e755b183b87952b6e7b9f42323f4147ef1c59d5131ef3f758869e989.blob	application/octet-stream	\N	2026-05-08 04:26:11.855086+00	2026-05-08 04:26:11.855086+00	\N
e6e6075b-436f-4f28-96b9-96dfac1b5f5d	sha256:60d6c26fa669c9474b888f0a246efd582466515f2e6f7c5a4a167165b9d54a15	1536	/data/blobs/nginx/nginx/60d6c26fa669c9474b888f0a246efd582466515f2e6f7c5a4a167165b9d54a15.blob	application/octet-stream	\N	2026-05-08 04:26:11.872478+00	2026-05-08 04:26:11.872478+00	\N
4cb25b3b-b3e4-4115-a82b-4f133253e393	sha256:6dcf135313f4f55eb70a16f3b30f5437c1217dce6aad6d1b8275988d2ae042d7	10752	/data/blobs/nginx/nginx/6dcf135313f4f55eb70a16f3b30f5437c1217dce6aad6d1b8275988d2ae042d7.blob	application/octet-stream	\N	2026-05-08 04:26:11.8828+00	2026-05-08 04:26:11.8828+00	\N
06b2f8d0-b26b-4e60-99ed-3b570eb9eabc	sha256:22870bfaf0ac54368f0f3c2bcdb50adb5c540b287e11cda8433624501d5479d3	1461	/data/blobs/nginx/nginx/22870bfaf0ac54368f0f3c2bcdb50adb5c540b287e11cda8433624501d5479d3.blob	application/octet-stream	\N	2026-05-08 04:26:11.884635+00	2026-05-08 04:26:11.884635+00	\N
de9a03dd-3908-4d29-978d-f76f1625817f	sha256:418660383d77d47cf283cf5f75928df3b282bc504942390a46161f0c99fc7578	482	/data/blobs/nginx/nginx/418660383d77d47cf283cf5f75928df3b282bc504942390a46161f0c99fc7578.blob	application/octet-stream	\N	2026-05-08 04:26:11.886307+00	2026-05-08 04:26:11.886307+00	\N
dca079a7-6e49-4420-a761-2823cb30b008	sha256:08446aacb69c6ff4aafd30c0c5fa485ab84ee2adfac922b8f9fff9b793b6733d	363	nginx/nginx/08446aacb69c6ff4aafd30c0c5fa485ab84ee2adfac922b8f9fff9b793b6733d.blob	application/octet-stream	\N	2026-05-08 05:32:15.825487+00	2026-05-08 05:32:15.825487+00	\N
3b506852-fabd-4ccf-a7f0-f8628344e5ed	sha256:7c4117be0eb549922f1739eaa64a0a5106b0e75295c68d550b0b827d9034b2bd	59904	nginx/nginx/7c4117be0eb549922f1739eaa64a0a5106b0e75295c68d550b0b827d9034b2bd.blob	application/octet-stream	\N	2026-05-08 05:32:15.835619+00	2026-05-08 05:32:15.835619+00	\N
16b5c000-3d17-4cce-87e0-8cd61cbe73ee	sha256:cb1d1ef695104a32ec5835c05891c7baca566bff8bae0593ecb1b0d4a0497dc1	5632	nginx/nginx/cb1d1ef695104a32ec5835c05891c7baca566bff8bae0593ecb1b0d4a0497dc1.blob	application/octet-stream	\N	2026-05-08 05:32:15.844361+00	2026-05-08 05:32:15.844361+00	\N
d88b90d8-fb51-45ce-ba8c-d54e539d5f65	sha256:f4f195154b750a6d8f4e2f07af01726a2b95b9c0bc259075f780f693ee3bcc97	482	nginx/nginx/f4f195154b750a6d8f4e2f07af01726a2b95b9c0bc259075f780f693ee3bcc97.blob	application/octet-stream	\N	2026-05-08 05:32:15.853687+00	2026-05-08 05:32:15.853687+00	\N
db7f93cd-5615-44ab-a8fd-f2f802749e2d	sha256:348e08b2ecd651e57b0151c6e78f9005ec7dfadacecb911bed084a5df69c53f5	482	nginx/nginx/348e08b2ecd651e57b0151c6e78f9005ec7dfadacecb911bed084a5df69c53f5.blob	application/octet-stream	\N	2026-05-08 05:32:15.860111+00	2026-05-08 05:32:15.860111+00	\N
afc9b567-f148-4657-95f1-1abb6d4a6f47	sha256:43e653f84b79ba52711b0f726ff5a7fd1162ae9df4be76ca1de8370b8bbf9bb0	207177216	nginx/nginx/43e653f84b79ba52711b0f726ff5a7fd1162ae9df4be76ca1de8370b8bbf9bb0.blob	application/octet-stream	\N	2026-05-08 05:32:17.869668+00	2026-05-08 05:32:17.869668+00	\N
e65f4b65-a2e3-4d14-b4b4-339c1068359a	sha256:57141287d8bec95bdcb4427ef84c2b5092abcdf688643cd7f0e15dfb2f4d1c33	482	nginx/nginx/57141287d8bec95bdcb4427ef84c2b5092abcdf688643cd7f0e15dfb2f4d1c33.blob	application/octet-stream	\N	2026-05-08 05:32:17.89369+00	2026-05-08 05:32:17.89369+00	\N
45bd4d14-aed5-4228-9215-7e26e5a7f2e7	sha256:b53d7889c283cbbee179ece3bafa91231b850135f957f4cdaf7e77b827464431	239440896	nginx/nginx/b53d7889c283cbbee179ece3bafa91231b850135f957f4cdaf7e77b827464431.blob	application/octet-stream	\N	2026-05-08 05:32:20.055506+00	2026-05-08 05:32:20.055506+00	\N
55b5293b-b792-4d69-b7c6-7da584793532	sha256:39ac602dcec2163e1293fe7d220e9b444cc2641ebac2564f5e3f44dab8ad6351	482	nginx/nginx/39ac602dcec2163e1293fe7d220e9b444cc2641ebac2564f5e3f44dab8ad6351.blob	application/octet-stream	\N	2026-05-08 05:32:20.067248+00	2026-05-08 05:32:20.067248+00	\N
8f60feb4-abf3-4a89-b2a2-63c0645ebf71	sha256:8487e86fc6ee1f1d2e853821b42a1ce757fdef563278ffea8e89fb0feabc0f07	8327	nginx/nginx/8487e86fc6ee1f1d2e853821b42a1ce757fdef563278ffea8e89fb0feabc0f07.blob	application/octet-stream	\N	2026-05-08 05:32:20.074746+00	2026-05-08 05:32:20.074746+00	\N
6320eee4-45ee-418a-8b1a-fa5b9663c70e	sha256:962bf3b9c052e295feb94dab10550f126d6718c69e1752f983def059cd40d3cf	93184	nginx/nginx/962bf3b9c052e295feb94dab10550f126d6718c69e1752f983def059cd40d3cf.blob	application/octet-stream	\N	2026-05-08 05:32:20.082994+00	2026-05-08 05:32:20.082994+00	\N
798d9c51-5e5c-432a-9cce-9aba07293141	sha256:b4d8646fb53480262b8dfde3e254d6654c6fa8b9b2a4ea273317ef9b2e681e63	16057344	nginx/nginx/b4d8646fb53480262b8dfde3e254d6654c6fa8b9b2a4ea273317ef9b2e681e63.blob	application/octet-stream	\N	2026-05-08 05:32:20.201085+00	2026-05-08 05:32:20.201085+00	\N
9c5c28ae-aa37-48f0-86b9-341ec06fbeed	sha256:c964e799140ecdfd8f651e49f9586a6a6366ec13d5a42880cc305bed26860570	6116864	nginx/nginx/c964e799140ecdfd8f651e49f9586a6a6366ec13d5a42880cc305bed26860570.blob	application/octet-stream	\N	2026-05-08 05:32:20.263571+00	2026-05-08 05:32:20.263571+00	\N
03232f78-a869-43da-9fb2-24d56a2203ee	sha256:2907803f9740c7a0d7db7252f332b548f9c7ea6bb7b6015ac57c1bda211aa0a0	482	nginx/nginx/2907803f9740c7a0d7db7252f332b548f9c7ea6bb7b6015ac57c1bda211aa0a0.blob	application/octet-stream	\N	2026-05-08 05:32:20.271411+00	2026-05-08 05:32:20.271411+00	\N
988982aa-1851-448e-81c5-11bebff1c92b	sha256:414e2f55aadf6b5f75642986562fd0a7f4196123f5a224ede763a5a348793796	482	nginx/nginx/414e2f55aadf6b5f75642986562fd0a7f4196123f5a224ede763a5a348793796.blob	application/octet-stream	\N	2026-05-08 05:32:20.278176+00	2026-05-08 05:32:20.278176+00	\N
8006d9e1-5851-4690-9d71-63dae51f9d10	sha256:882cf81bf175aff9dffa4cf3b43779dc10f3885470fa60a1c39eb791b2168f43	5120	nginx/nginx/882cf81bf175aff9dffa4cf3b43779dc10f3885470fa60a1c39eb791b2168f43.blob	application/octet-stream	\N	2026-05-08 05:32:20.285866+00	2026-05-08 05:32:20.285866+00	\N
00f28c9f-5099-4775-98de-82aca8c50cce	sha256:9a7b8a796d71e0cec71cd51f9fca7a4db82aeb08d71cf1d6778ab30a07a9cbfc	482	nginx/nginx/9a7b8a796d71e0cec71cd51f9fca7a4db82aeb08d71cf1d6778ab30a07a9cbfc.blob	application/octet-stream	\N	2026-05-08 05:32:20.293452+00	2026-05-08 05:32:20.293452+00	\N
26acdbee-bff2-4d9f-a7b8-0495be48795c	sha256:4ed6ad840947b0dc7b449ec47cbc372eeba689324eb4307010db91bddceb1d85	482	nginx/nginx/4ed6ad840947b0dc7b449ec47cbc372eeba689324eb4307010db91bddceb1d85.blob	application/octet-stream	\N	2026-05-08 05:32:20.300318+00	2026-05-08 05:32:20.300318+00	\N
e6130381-4869-44ba-9428-dc27b6eb0b4d	sha256:90ae8819949669d51b4ce3e1d0d7b7afe084a53dfe81db4d51f84b44e717d6a7	482	nginx/nginx/90ae8819949669d51b4ce3e1d0d7b7afe084a53dfe81db4d51f84b44e717d6a7.blob	application/octet-stream	\N	2026-05-08 05:32:20.317058+00	2026-05-08 05:32:20.317058+00	\N
be2e1f7e-0b73-4234-b533-80dcfc1f3634	sha256:6ca017c7db4ebaaaed01763dc259e93ce9fc45b60d27f2ced95d1df4c3e88a08	482	nginx/nginx/6ca017c7db4ebaaaed01763dc259e93ce9fc45b60d27f2ced95d1df4c3e88a08.blob	application/octet-stream	\N	2026-05-08 05:32:20.327029+00	2026-05-08 05:32:20.327029+00	\N
c27393d8-cac1-406c-bbac-beb03e6670d4	sha256:d98fa29adb0722ba012cbc570b3db641ebb498c3c1d71b7722beec96a30c74aa	7103488	nginx/nginx/d98fa29adb0722ba012cbc570b3db641ebb498c3c1d71b7722beec96a30c74aa.blob	application/octet-stream	\N	2026-05-08 05:32:20.399886+00	2026-05-08 05:32:20.399886+00	\N
3eaf8c9e-bb97-4e06-a717-a093ae2b2733	sha256:173e7c0101b800ee97d38de0fe75f5310cf28c2bb02c7f787ec4d2111ee2db0a	4096	nginx/nginx/173e7c0101b800ee97d38de0fe75f5310cf28c2bb02c7f787ec4d2111ee2db0a.blob	application/octet-stream	\N	2026-05-08 05:32:20.412989+00	2026-05-08 05:32:20.412989+00	\N
a30ed9dc-f4a2-46d0-914a-1a88be96d636	sha256:29440a1b5041d5a1539dd5a8a667bcbb380f966580e730c98e3e8d9e05bbb8e7	482	nginx/nginx/29440a1b5041d5a1539dd5a8a667bcbb380f966580e730c98e3e8d9e05bbb8e7.blob	application/octet-stream	\N	2026-05-08 05:32:20.420491+00	2026-05-08 05:32:20.420491+00	\N
e6810555-a7df-4956-8445-f8a7ca060c79	sha256:e66cc8adc0f42b3919b378aa30d36bb98f4fbf4156f4acc5ddc427f2aed9c35d	2374	nginx/nginx/e66cc8adc0f42b3919b378aa30d36bb98f4fbf4156f4acc5ddc427f2aed9c35d.blob	application/octet-stream	\N	2026-05-08 05:32:20.430138+00	2026-05-08 05:32:20.430138+00	\N
adf8725a-449e-47b1-a72b-ee2674918ad6	sha256:faa1ac83b5e393fc952f0c3dc586d7b8e40d961e3f9e8038b36b8aefad8397bc	25088	nginx/nginx/faa1ac83b5e393fc952f0c3dc586d7b8e40d961e3f9e8038b36b8aefad8397bc.blob	application/octet-stream	\N	2026-05-08 05:32:20.438722+00	2026-05-08 05:32:20.438722+00	\N
ca196374-1109-43b0-9002-ba1ae26729bf	sha256:33e47575beaceb9c31f694d08e759af8731da14ab8c43370c6455dd5644134f8	2560	nginx/nginx/33e47575beaceb9c31f694d08e759af8731da14ab8c43370c6455dd5644134f8.blob	application/octet-stream	\N	2026-05-08 05:32:20.446151+00	2026-05-08 05:32:20.446151+00	\N
c2f8f8b4-0284-47da-88da-2568c3d91c2c	sha256:34e327373d1e16b8414545a3779549c3f715d13f307e58134c5acc142ffdde34	406	nginx/nginx/34e327373d1e16b8414545a3779549c3f715d13f307e58134c5acc142ffdde34.blob	application/octet-stream	\N	2026-05-08 05:32:20.453632+00	2026-05-08 05:32:20.453632+00	\N
3e494e28-f1c4-4648-aeaa-4b63ac3ecc26	sha256:86bb2d38a7fd4bbaafe341bba1cdecf3e3c8ac0aa3415c29f7e83c5417fc3b93	1969664	nginx/nginx/86bb2d38a7fd4bbaafe341bba1cdecf3e3c8ac0aa3415c29f7e83c5417fc3b93.blob	application/octet-stream	\N	2026-05-08 05:32:20.478896+00	2026-05-08 05:32:20.478896+00	\N
7ea4ac08-252f-4a5e-8a8b-9e81aa306844	sha256:a869887419e2d928d0afac25ee4837f4b06ed14495cc8d864d12c6254ad034e1	2175	nginx/nginx/a869887419e2d928d0afac25ee4837f4b06ed14495cc8d864d12c6254ad034e1.blob	application/octet-stream	\N	2026-05-08 05:32:20.486363+00	2026-05-08 05:32:20.486363+00	\N
1a631fc0-9e76-4e91-9908-15c08b79ccc7	sha256:ea8af36b77296b2f551024eeba9d724661bfe88f84ec7048493db4cb49129572	5120	nginx/nginx/ea8af36b77296b2f551024eeba9d724661bfe88f84ec7048493db4cb49129572.blob	application/octet-stream	\N	2026-05-08 05:32:20.494532+00	2026-05-08 05:32:20.494532+00	\N
cbf583b0-8e55-44a2-9040-4e1117766cab	sha256:f04c7f16f0b83b0bca555664be6d17e6a23fa3a67cef591161445c81f8fd02e1	482	nginx/nginx/f04c7f16f0b83b0bca555664be6d17e6a23fa3a67cef591161445c81f8fd02e1.blob	application/octet-stream	\N	2026-05-08 05:32:20.502115+00	2026-05-08 05:32:20.502115+00	\N
7bb871a1-b5e7-4e6b-bfe5-2d7bd64ea2a3	sha256:b273004037cc3af245d8e08cfbfa672b93ee7dcb289736c82d0b58936fb71702	7808	nginx/fastdfs/b273004037cc3af245d8e08cfbfa672b93ee7dcb289736c82d0b58936fb71702.blob	application/octet-stream	\N	2026-05-08 06:22:52.048984+00	2026-05-08 06:22:52.048984+00	\N
05fc9049-a001-402c-84d5-b1652e64fe37	sha256:9c742cd6c7a5752ee36be8ecb14be45c0885e10e6dd34f26a9ae3eb096c5d492	129195520	nginx/fastdfs/9c742cd6c7a5752ee36be8ecb14be45c0885e10e6dd34f26a9ae3eb096c5d492.blob	application/octet-stream	\N	2026-05-08 06:22:53.400369+00	2026-05-08 06:22:53.400369+00	\N
9b3101bf-e9b8-4d19-945e-e7dc82c2dda8	sha256:03127cdb479b0f1eb8a9b0df8e8d72ead24979728d3c84ff645611b9d8790f94	11301376	nginx/fastdfs/03127cdb479b0f1eb8a9b0df8e8d72ead24979728d3c84ff645611b9d8790f94.blob	application/octet-stream	\N	2026-05-08 06:22:53.49287+00	2026-05-08 06:22:53.49287+00	\N
c47ecc6d-06d1-448f-9041-676f8422654f	sha256:293d5db30c9fcf33b65fa033e427fdd118464f9ea0c2a343a478a6e89c29140e	19311616	nginx/fastdfs/293d5db30c9fcf33b65fa033e427fdd118464f9ea0c2a343a478a6e89c29140e.blob	application/octet-stream	\N	2026-05-08 06:22:53.886954+00	2026-05-08 06:22:53.886954+00	\N
aca955bc-63b4-4419-a0c7-90415c66477f	sha256:9b55156abf262eac3e6bd3ae60e7277ab4f9c69543650d7ecefc8c26ee889873	156534784	nginx/fastdfs/9b55156abf262eac3e6bd3ae60e7277ab4f9c69543650d7ecefc8c26ee889873.blob	application/octet-stream	\N	2026-05-08 06:22:55.773008+00	2026-05-08 06:22:55.773008+00	\N
0c13616d-96e3-4e46-a5c3-0baf3b934325	sha256:b626401ef603dd383fc3a43cf474186827db1875591bfc84b178177ca010015b	11739648	nginx/fastdfs/b626401ef603dd383fc3a43cf474186827db1875591bfc84b178177ca010015b.blob	application/octet-stream	\N	2026-05-08 06:22:55.901736+00	2026-05-08 06:22:55.901736+00	\N
5493a3a9-d0c2-4d4a-ad3e-e30b92bb8034	sha256:53a0b163e9955ffb80569ef37e13fbf5d1074ddd67bc5ad09d7bd874b800396a	3584	nginx/fastdfs/53a0b163e9955ffb80569ef37e13fbf5d1074ddd67bc5ad09d7bd874b800396a.blob	application/octet-stream	\N	2026-05-08 06:22:55.912122+00	2026-05-08 06:22:55.912122+00	\N
c603f090-157f-4cd2-8c1e-50c964f3e030	sha256:6b5aaff4425423d122ebe4f1514a1994ae60954fc8a2299787df0ddb1a12f6b9	209758208	nginx/fastdfs/6b5aaff4425423d122ebe4f1514a1994ae60954fc8a2299787df0ddb1a12f6b9.blob	application/octet-stream	\N	2026-05-08 06:22:57.31181+00	2026-05-08 06:22:57.31181+00	\N
\.


--
-- Data for Name: manifest_blobs; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.manifest_blobs (blob_id, manifest_id) FROM stdin;
\.


--
-- Data for Name: manifests; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.manifests (id, repository_id, digest, media_type, config_digest, config_size, layers_count, total_size, created_at, updated_at, deleted_at) FROM stdin;
8efd4b80-c0f6-4782-a982-40f3d27309f9	6b8f0c98-d3e0-45cd-89be-920db1e51743	sha256:361b78afe6648f0999af7423e4dbfe795380b4666694d0c5fef3233e009ae4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:361b78afe6648f0999af7423e4dbfe795380b4666694d0c5fef3233e009ae4fd	356	25	519577032	2026-04-27 09:58:54.827134+00	2026-04-27 09:58:54.827134+00	\N
63dd2e89-2bff-4c26-8245-75b1d71045ad	997725f7-3cdf-4c7a-850d-f83d7beefbdd	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json		0	0	8466	2026-04-28 22:12:37.431644+00	2026-04-28 22:12:37.431644+00	\N
fb202d3b-90e2-4da2-9acf-a15d9adc513a	997725f7-3cdf-4c7a-850d-f83d7beefbdd		application/vnd.docker.distribution.manifest.v2+json		0	0	0	2026-04-28 22:12:37.45639+00	2026-04-28 22:12:37.45639+00	\N
5536cca5-bdf4-49d8-82c5-d4e853132470	8bc3701e-0aba-4065-ac2c-b08e925aa10a	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json		0	0	8466	2026-04-29 01:40:20.924229+00	2026-04-29 01:40:20.924229+00	\N
7633220e-2da0-4a1f-bd75-8c11454647c8	c32bef13-21fc-4bc1-bde9-14e9d67c5a02	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json		0	0	8466	2026-04-29 01:43:34.772729+00	2026-04-29 01:43:34.772729+00	\N
68e7e6a5-1263-481a-8b26-762399894d87	6b8f0c98-d3e0-45cd-89be-920db1e51743	sha256:cf0656a5b13bedc4a1707ececdc7c6186e8178310687a14e83ee6f87715fb65c	application/vnd.docker.distribution.manifest.v2+json	sha256:cf0656a5b13bedc4a1707ececdc7c6186e8178310687a14e83ee6f87715fb65c	404	21	176257927	2026-04-29 01:47:27.539899+00	2026-04-29 01:47:27.539899+00	\N
ecf48bab-e6fc-4b20-8a37-387d19fb11cd	13c059d3-5090-4ebf-85c4-3a582584cea7	sha256:a73af32908456ebfda8ae9d9cb0fd84399eaa29ce132d2f108eca5906ed7c5a6	application/vnd.docker.distribution.manifest.v2+json	sha256:a73af32908456ebfda8ae9d9cb0fd84399eaa29ce132d2f108eca5906ed7c5a6	373	9	9980519	2026-04-29 01:51:32.524111+00	2026-04-29 01:51:32.524111+00	\N
f4e33578-4ee4-4915-8eb7-e47f2a8c02a7	91f7c195-f1e7-47c2-958d-cd9547f9cf27	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375893930	2026-04-29 02:36:08.395531+00	2026-04-29 02:36:08.395531+00	\N
2641b691-e55a-4ebc-b441-80a16d1151be	3b614046-d798-45a7-8dd0-25005d3ea6b6	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375893930	2026-04-29 03:09:51.321064+00	2026-04-29 03:09:51.321064+00	\N
5468e998-e94d-445b-a5db-47e7e0b62a70	980228e6-bda3-4082-b29f-bc8646188a6b	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375893930	2026-04-29 03:27:35.180763+00	2026-04-29 03:27:35.180763+00	\N
16b7e925-fba9-458f-b038-520b9703e024	55d7a861-8b42-4eea-8d22-20156723eb39	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375893930	2026-04-29 04:30:45.865154+00	2026-04-29 04:30:45.865154+00	\N
08bba224-f974-470d-883a-32d70e8fd0aa	91f7c195-f1e7-47c2-958d-cd9547f9cf27	sha256:4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953	application/vnd.docker.distribution.manifest.v2+json	sha256:4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953	362	17	191799099	2026-04-29 04:32:49.957096+00	2026-04-29 04:32:49.957096+00	\N
b88153ba-de5d-4fd8-ba26-28a249a73efc	09b00111-4f5e-4d7e-93a8-5c0f13b9505a	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375893930	2026-04-29 04:35:52.304364+00	2026-04-29 04:35:52.304364+00	\N
8bcb40d4-14ed-4b88-96ce-766cc425eb77	d32e0a68-8a9c-45d1-8764-c675fc050c46	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375893930	2026-04-29 05:37:45.886196+00	2026-04-29 05:37:45.886196+00	\N
ac432b13-7bbc-4f92-b9d0-98b6a01a446f	73c9584c-640c-46d6-9fa7-e0596d7c76ae	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375893930	2026-04-29 05:53:42.920783+00	2026-04-29 05:53:42.920783+00	\N
7d27368a-acbe-4287-9cef-d3b69a9dd061	3e7fef21-8c67-4a8f-a026-cee770d974f5	sha256:cf0656a5b13bedc4a1707ececdc7c6186e8178310687a14e83ee6f87715fb65c	application/vnd.docker.distribution.manifest.v2+json	sha256:cf0656a5b13bedc4a1707ececdc7c6186e8178310687a14e83ee6f87715fb65c	404	21	61	2026-05-08 03:49:23.340484+00	2026-05-08 04:23:33.750771+00	\N
af04d5e8-5b4a-4f23-b539-47f6452a0c1a	3e7fef21-8c67-4a8f-a026-cee770d974f5	sha256:4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953	application/vnd.docker.distribution.manifest.v2+json	sha256:4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953	362	17	59	2026-05-07 03:17:45.009569+00	2026-05-08 04:23:36.189748+00	\N
834a77ee-725c-4362-8184-32ee3afdb3cd	13c059d3-5090-4ebf-85c4-3a582584cea7	sha256:53d9d0a6248d809c6939e3f7ed36aae34163535d1682a57cca4bc1921c50abdd	application/vnd.docker.distribution.manifest.v2+json	sha256:5bd7bd52e5bcab15a093466b90e37472b0d0c0081052522afb8924cbdaf15f56	0	8	26001051	2026-05-06 10:58:30.184341+00	2026-05-08 04:23:53.380002+00	\N
84743dd8-49ab-4445-b556-5c8fca7c43b1	13c059d3-5090-4ebf-85c4-3a582584cea7	sha256:4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953	application/vnd.docker.distribution.manifest.v2+json	sha256:4263f71e9e2fe863fbb1063eb4b6fa28b8a6cea6f22dacf49d502063a18c0953	362	17	62	2026-04-30 01:18:11.137625+00	2026-05-08 04:23:57.345639+00	\N
3ab094e7-a779-419f-8d39-65f61619bd73	13c059d3-5090-4ebf-85c4-3a582584cea7	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	application/vnd.docker.distribution.manifest.v2+json	sha256:e61dc59bf74bb9250a460109788ba2d815f6d0794afaac7638430ca6be0ee741	0	39	375896671	2026-04-29 02:02:51.415465+00	2026-05-08 04:24:09.37809+00	\N
ec3efc3a-6d80-4dc1-a684-a0beab7280e6	13c059d3-5090-4ebf-85c4-3a582584cea7	sha256:a18522803a50ed623d7e4f1ddbe04b9f423ce33a07f2c4ed46e11d47d100c5cd	application/vnd.docker.distribution.manifest.v2+json	sha256:499b951337574fb4ac911fc38a061589c14b501ebc4b10da144ed9144e2ec402	0	8	154773333	2026-04-30 01:14:08.363889+00	2026-05-08 04:24:10.617407+00	\N
66b30ea5-1b23-4f2a-b2ae-663c639321a0	d15e9e85-a189-4759-a386-840ac511fd86	sha256:d91cb46d06a5185ab4804caba0370d9de3de8cdac516f32518ef9b0f6c629946	application/vnd.docker.distribution.manifest.v2+json	sha256:d7d7dbd2794ebb8af807c4592af3e0c88d0eca1d84472d23afb82f60e3fb1bed	0	8	111840764	2026-05-08 06:11:23.733274+00	2026-05-08 06:11:34.025693+00	2026-05-08 06:20:38.583018+00
5e0ee005-b11b-4265-88e6-e3e9f5a509b4	4ea614ce-a986-4487-b62f-f4b66d0a9f09	sha256:d7d7dbd2794ebb8af807c4592af3e0c88d0eca1d84472d23afb82f60e3fb1bed	application/vnd.docker.distribution.manifest.v2+json	sha256:d7d7dbd2794ebb8af807c4592af3e0c88d0eca1d84472d23afb82f60e3fb1bed	356	19	65	2026-05-08 04:26:10.885729+00	2026-05-08 05:30:10.448225+00	\N
08fff065-bd97-45b4-b867-ebc7c11afe21	4ea614ce-a986-4487-b62f-f4b66d0a9f09	sha256:0c60c9f55beef0e645bc75f87273e64905cb0f4c9a60f4ac07434eaae1567822	application/vnd.docker.distribution.manifest.v2+json	sha256:d7d7dbd2794ebb8af807c4592af3e0c88d0eca1d84472d23afb82f60e3fb1bed	0	19	111856055	2026-05-08 05:30:46.185564+00	2026-05-08 05:31:08.127188+00	\N
0fc34bab-d312-41a1-8c05-117ab45343e6	4ea614ce-a986-4487-b62f-f4b66d0a9f09	sha256:ab4e1db900e4a85fb3873b25ab226068fd8b0389b4311b72bf0c10e92124a682	application/vnd.docker.distribution.manifest.v2+json	sha256:08446aacb69c6ff4aafd30c0c5fa485ab84ee2adfac922b8f9fff9b793b6733d	0	31	478085605	2026-05-08 05:32:20.515581+00	2026-05-08 05:32:20.515581+00	\N
cfe6c5e9-ccbc-4084-960c-142ebad3c7f5	58035b84-fa3c-4fa4-907a-591eda623b48	sha256:985c83f2f0639d2aad30eeec0d2d2ecd625506736cf1c9433a896420d2f4914f	application/vnd.docker.distribution.manifest.v2+json	sha256:5107333e08a87b836d48ff7528b1e84b9c86781cc9f1748bbc1b8c42a870d933	0	11	519565335	2026-05-08 06:36:05.286376+00	2026-05-08 06:36:05.286376+00	\N
37bb7054-018b-4e30-bef4-e8158bd85c27	4ea614ce-a986-4487-b62f-f4b66d0a9f09	sha256:5486b5eaa8a03eedc2d6f26865ada3de927e9aa690f9e79ea65120bf78a2ce3b	application/vnd.docker.distribution.manifest.v2+json	sha256:cf0656a5b13bedc4a1707ececdc7c6186e8178310687a14e83ee6f87715fb65c	0	21	176254842	2026-05-08 05:40:52.332173+00	2026-05-08 05:40:52.332173+00	2026-05-08 06:12:45.400127+00
092b3a8a-499c-4e41-b501-06259c807663	31c7d765-af92-4f0a-855c-22fc9bc1aa82	sha256:a4041060de6a4615587dbd43acae7301c1451a4430136f0e1cb4a26671ca10c4	application/vnd.docker.distribution.manifest.v2+json	sha256:b273004037cc3af245d8e08cfbfa672b93ee7dcb289736c82d0b58936fb71702	0	7	537853143	2026-05-08 06:22:57.323806+00	2026-05-08 06:32:40.530773+00	2026-05-08 06:32:43.314008+00
88a232d8-da7d-4130-8cff-350cb1dc282d	f96e7bab-f4a5-45cc-bbc7-f7b0d27b264d	sha256:6a3086003e748421a6978390c0c28f0ce597c48427631264d0f755b9f3668acc	application/vnd.docker.distribution.manifest.v2+json	sha256:7705dd2858c100a95bba6140201b5c5315926c54d94a1577c6fa57876780d9ad	0	8	111849132	2026-05-08 06:34:45.832532+00	2026-05-08 06:35:34.621401+00	\N
\.


--
-- Data for Name: namespaces; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.namespaces (id, name, display_name, description, is_public, owner_id, created_at, updated_at, deleted_at) FROM stdin;
1e9449d6-cda3-4bb2-a27b-75b7b5871ffb	jvv			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 01:42:44.182281+00	2026-04-29 01:42:44.182281+00	2026-04-29 01:50:57.339004+00
159aceae-b1ac-47f9-8f5a-3197e050c3bd	qwen3-coder			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-28 23:33:22.752855+00	2026-04-28 23:33:22.752855+00	2026-04-29 01:50:59.851328+00
8885854f-fce0-46c5-9185-a3319171dc27	111	111	111	t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-27 09:56:47.56086+00	2026-04-27 09:56:47.56086+00	2026-04-29 03:14:03.123743+00
38747182-f496-4ffa-988e-491c0e7d88c6	ocloudhub	ocloudhub		t	\N	2026-04-28 22:12:37.422445+00	2026-04-28 22:12:37.422445+00	2026-04-29 04:30:18.13818+00
4f28df0a-574e-4a89-9694-0be98041171b	12313212414			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 09:21:06.52173+00	2026-04-29 09:21:06.52173+00	2026-04-30 06:22:28.22669+00
ba10de43-b7ef-41b9-9af9-ef16ba74a38c	123123124124			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 09:21:03.221038+00	2026-04-29 09:21:03.221038+00	2026-04-30 06:22:30.143535+00
4a221bf0-7a0f-4f10-946d-f08677f7f1d0	123123124142			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 09:20:59.621374+00	2026-04-29 09:20:59.621374+00	2026-04-30 06:22:31.845484+00
8e109ed7-cea9-44a7-b89d-d4c764d224bc	123124145			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 09:21:12.805834+00	2026-04-29 09:21:12.805834+00	2026-04-30 06:22:33.610023+00
de624112-7aae-4dbb-a4f5-389ec12a53f1	1241421541			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 09:20:56.601471+00	2026-04-29 09:20:56.601471+00	2026-04-30 06:22:35.009282+00
113703b0-76d2-4fe7-8e70-f5b28dd9d381	1111			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 05:23:26.890254+00	2026-04-30 05:23:26.890254+00	2026-04-30 06:22:36.460954+00
d68af736-b143-4e72-a475-1778363ab89a	123123			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 09:20:53.31479+00	2026-04-29 09:20:53.31479+00	2026-04-30 06:22:38.380487+00
a6c000df-936d-4c9a-9784-425bbd9aff31	1112312314			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 08:55:17.40514+00	2026-04-29 08:55:17.40514+00	2026-04-30 06:22:39.717845+00
f81f8997-d175-420f-b3d0-46d67667dc7d	12312312414			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 05:55:13.322314+00	2026-04-30 05:55:13.322314+00	2026-04-30 06:22:41.341203+00
3053acac-6d4b-4b80-ac24-17cd626caf03	siyou1			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 05:55:42.355826+00	2026-04-30 05:55:42.355826+00	2026-04-30 06:22:44.192924+00
35c9805a-fcf0-465f-9d10-83e6b30bd1e8	1123123124124			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 06:53:51.520041+00	2026-04-30 06:53:51.520041+00	2026-04-30 09:51:53.440433+00
95c262ad-d600-4d34-84c1-9c9772ffe4b3	ceshi			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 06:54:11.792689+00	2026-04-30 06:54:11.792689+00	2026-04-30 09:51:55.118679+00
3ec25b96-6fb7-452b-b3ee-3ed7ef5a2ea7	test-private2			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 07:00:45.665566+00	2026-04-30 07:00:45.665566+00	2026-04-30 10:08:25.260268+00
c5961fc6-f1d3-4066-b155-c6c1c2d3234f	test-private3			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 07:10:33.814688+00	2026-04-30 07:10:33.814688+00	2026-04-30 10:08:26.77837+00
abf01f64-9284-4703-ad2f-d12db8b5ae4f	final-test-private			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 07:18:51.484847+00	2026-04-30 07:18:51.484847+00	2026-04-30 10:08:28.13505+00
9950f0e4-99ce-4eb0-86e8-02d4c1cab1bf	verify-private			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 07:22:10.755739+00	2026-04-30 07:22:10.755739+00	2026-04-30 10:08:32.200245+00
01253c47-bb2d-4e6f-bff5-663ee451c284	final-verify-private			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 07:26:42.059488+00	2026-04-30 07:26:42.059488+00	2026-04-30 10:08:33.864894+00
d24c3195-b2a8-4388-a97a-823f9e2a21be	public		public	f	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 09:52:15.134303+00	2026-04-30 09:52:15.134303+00	2026-04-30 10:08:37.517617+00
0bff377a-5520-4e8f-9393-5fd6be8ca3a2	hubadmin			t	178172f2-b066-43c6-9888-1f2a302d76b9	2026-05-01 14:43:18.261313+00	2026-05-01 14:43:18.261313+00	2026-05-06 00:40:57.942849+00
ada962d3-835a-4d32-b311-fd9f2584b8dd	hubpub22			f	178172f2-b066-43c6-9888-1f2a302d76b9	2026-05-01 14:46:55.200296+00	2026-05-01 14:46:55.200296+00	2026-05-06 00:40:59.126988+00
f37b0062-4bf9-4031-9648-d22a09c120cc	hubpub			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-01 14:41:33.547104+00	2026-05-01 14:41:33.547104+00	2026-05-06 00:41:00.199664+00
034ce41a-ca67-4c81-9187-f09f71d50836	hubhub			f	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-01 14:40:23.000832+00	2026-05-01 14:40:23.000832+00	2026-05-06 00:41:01.723191+00
24d1ee66-b8a7-43ee-85da-c7a5c52fbdf7	ceshiyixia			f	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 10:08:45.577036+00	2026-04-30 10:08:45.577036+00	2026-05-06 00:41:03.434952+00
0a6fb8f2-948f-4fd1-82e0-d9d8648e2802	zheshisiyouns			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 06:30:30.931703+00	2026-04-30 06:30:30.931703+00	2026-05-06 00:41:05.690515+00
7c639c65-28d3-4c10-8dbe-619d5c49be88	siyou		这是一个私有命名空间	t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-30 05:55:29.618478+00	2026-04-30 06:23:37.885353+00	2026-05-06 00:41:07.212674+00
bf96ab06-5b0e-4f53-a80f-f104b5cbbee4	222222222			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 05:52:44.871151+00	2026-04-29 05:52:44.871151+00	2026-05-06 00:41:08.569392+00
0765d36a-dd9f-44ec-9cd8-80331c224851	asd			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 03:26:45.100945+00	2026-04-29 03:26:45.100945+00	2026-05-06 00:41:10.285216+00
ee2b14ee-9975-4d5f-9668-2ed7a170181a	1111111	11111111111		t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 03:08:30.658422+00	2026-04-29 03:08:30.658422+00	2026-05-06 00:41:11.843762+00
943ae870-a84e-40ef-b5d6-77368a87df74	CCC			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-06 15:22:49.698348+00	2026-05-06 15:22:49.698348+00	2026-05-06 23:47:53.112459+00
35ae0a13-32bb-46c7-bee9-36537a70da92	BBB			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-06 15:22:45.420105+00	2026-05-06 15:22:45.420105+00	2026-05-06 23:47:54.543298+00
44f7fb2a-6db9-4f2d-92b2-8f54aebe869d	AAA			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-06 15:22:36.642713+00	2026-05-06 15:22:36.642713+00	2026-05-06 23:47:56.40941+00
bd0a2e39-ca61-4175-95f2-86e93fab7225	jjjj			f	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-08 03:43:33.016729+00	2026-05-08 03:43:33.016729+00	2026-05-08 04:24:29.706346+00
cf9da0d8-90d3-4024-9639-49f8eb671e80	3333			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-06 15:22:30.880134+00	2026-05-06 15:22:30.880134+00	2026-05-08 04:24:43.846658+00
7d5c8af3-f945-4eaf-82de-c87461bf0c32	222			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-06 15:22:27.313137+00	2026-05-06 15:22:27.313137+00	2026-05-08 04:24:58.4283+00
7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	11111	111111	描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息描述信息	t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-04-29 01:51:14.493804+00	2026-04-30 04:52:39.393481+00	2026-05-08 04:25:16.852754+00
d3939621-c03c-4f4a-8d3f-05e9aad02cb9	nginx			t	52238353-e4f1-4bd7-8894-3426b3b152ee	2026-05-08 01:17:41.339872+00	2026-05-08 01:17:41.339872+00	2026-05-08 06:33:18.328727+00
488702f2-5cd8-4a8f-a054-10c3a2926581	psychocare			t	5c894435-98c8-4ee3-8008-5c99311801fa	2026-05-08 06:33:30.149612+00	2026-05-08 06:33:30.149612+00	\N
\.


--
-- Data for Name: registry_endpoints; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.registry_endpoints (id, name, url, type, auth_type, username, password, access_token, refresh_token, insecure_skip_verify, timeout_seconds, is_enabled, last_test_time, last_test_result, last_error_message, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: replication_policies; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.replication_policies (id, name, description, source_registry, source_namespace, source_repository, source_tag_pattern, dest_registry, dest_namespace, dest_repository, trigger_type, trigger_cron, trigger_event, delete_remote, override, enabled, last_trigger_time, last_success_time, last_failure_time, success_count, failure_count, created_at, updated_at, deleted_at) FROM stdin;
19731ed5-cbd1-436e-8a9c-8953bec8c347	111	111	111					11111		manual			f	t	t	2026-05-06 00:42:57.544927+00	\N	\N	0	0	2026-05-06 00:42:26.910557+00	2026-05-06 00:42:57.553941+00	2026-05-06 00:43:33.154392+00
\.


--
-- Data for Name: replication_task_details; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.replication_task_details (id, task_id, resource_type, source_namespace, source_repository, source_tag, source_digest, status, dest_namespace, dest_repository, dest_tag, started_at, ended_at, bytes_transferred, error_message, created_at, updated_at, deleted_at) FROM stdin;
d76e5a30-a2c3-4de1-b1c5-97fe9aa7f208	1c035eca-66d2-4bc4-b687-b5f532d2b805	image	library	nginx	latest		failed				2026-04-28 03:54:18.9388+00	2026-04-28 03:54:18.96574+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T03:54:18Z" level=fatal msg="Invalid destination name docker://http://registry-core:5000/library/nginx:latest: invalid reference format"\n	2026-04-28 03:54:18.938906+00	2026-04-28 03:54:18.966037+00	\N
5190b5f1-257a-4f42-bc1c-16ea5c6cd0cc	407238c4-3952-40fb-b227-4a08e30f2cbc	image	library	nginx	latest		failed				2026-04-28 03:57:36.257677+00	2026-04-28 03:59:43.378126+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T03:58:06Z" level=warning msg="Failed, retrying in 1s ... (1/3). Error: initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T03:58:37Z" level=warning msg="Failed, retrying in 2s ... (2/3). Error: initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T03:59:09Z" level=warning msg="Failed, retrying in 4s ... (3/3). Error: initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T03:59:43Z" level=fatal msg="initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\n	2026-04-28 03:57:36.258006+00	2026-04-28 03:59:43.378727+00	\N
b1197e2c-89f8-4566-aea5-16b703ff572e	5c448849-d81c-437f-af7a-4065dd04f5e2	image	library	nginx	alpine		failed				2026-04-28 04:10:18.55318+00	2026-04-28 04:12:26.182919+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T04:10:48Z" level=warning msg="Failed, retrying in 1s ... (1/3). Error: initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T04:11:19Z" level=warning msg="Failed, retrying in 2s ... (2/3). Error: initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T04:11:51Z" level=warning msg="Failed, retrying in 4s ... (3/3). Error: initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T04:12:26Z" level=fatal msg="initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\n	2026-04-28 04:10:18.553626+00	2026-04-28 04:12:26.184248+00	\N
82af2b70-f63b-406c-9bef-36f6817b3660	555f7fcf-2dda-4007-b02e-aaf39ee09610	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 08:30:04.844654+00	2026-04-28 08:30:05.51174+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T08:30:05Z" level=fatal msg="trying to reuse blob sha256:302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab at destination: pinging container registry registry-core:5000: Get \\"https://registry-core:5000/v2/\\": http: server gave HTTP response to HTTPS client"\n	2026-04-28 08:30:04.844862+00	2026-04-28 08:30:05.511942+00	\N
71ebc068-e278-4b4d-ab33-6cf562da9e00	2c651951-b5f9-493c-a1c1-e2b812538934	image	ocloudhub	nginx-proxy-manager	latest		failed				2026-04-28 08:30:58.651508+00	2026-04-28 08:30:58.972194+00	0	skopeo执行失败: exit status 2, stderr: time="2026-04-28T08:30:58Z" level=fatal msg="initializing source docker://registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:latest: reading manifest latest in registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager: manifest unknown"\n	2026-04-28 08:30:58.651643+00	2026-04-28 08:30:58.972422+00	\N
5e9f9d2f-1e90-4a6b-80fb-1b2f6d1499d9	4a2da474-2555-42ba-8a3e-904051979c5d	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 08:31:59.913991+00	2026-04-28 08:32:00.424836+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T08:32:00Z" level=fatal msg="trying to reuse blob sha256:302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab at destination: pinging container registry registry-core:5000: Get \\"https://registry-core:5000/v2/\\": http: server gave HTTP response to HTTPS client"\n	2026-04-28 08:31:59.914073+00	2026-04-28 08:32:00.425104+00	\N
e191d0eb-5aa9-4be9-907b-339d77489b82	17112487-784f-49fe-b349-3fd22823462c	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 08:42:38.275771+00	2026-04-28 08:42:41.179202+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T08:42:41Z" level=fatal msg="writing blob: uploading layer chunked: StatusCode: 404, \\"404 page not found\\""\n	2026-04-28 08:42:38.275971+00	2026-04-28 08:42:41.180016+00	\N
d3d80cc3-52f5-4296-8d40-62737d740875	8a59841d-f39b-4126-a8f0-adfd58051ab2	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 11:47:47.258822+00	2026-04-28 11:47:49.72136+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T11:47:49Z" level=fatal msg="writing blob: initiating layer upload to /v2/ocloudhub/nginx-proxy-manager/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 11:47:47.258944+00	2026-04-28 11:47:49.722072+00	\N
b208b0a6-e237-4ca1-b4af-27c59d9d2316	8c7eef6f-ccab-43f5-bc67-242bae624f3f	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 14:07:28.101728+00	2026-04-28 14:07:28.134863+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:07:28Z" level=fatal msg="Invalid source name docker:// registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1: invalid reference format"\n	2026-04-28 14:07:28.102232+00	2026-04-28 14:07:28.135154+00	\N
5f154cd1-68e8-4e2a-903f-51b51d827d9d	c3df3de2-03ce-4305-a030-d60432692239	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 14:08:11.4605+00	2026-04-28 14:08:13.750403+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:08:13Z" level=fatal msg="writing blob: initiating layer upload to /v2/111/qwen3-coder-plus/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 14:08:11.460628+00	2026-04-28 14:08:13.750758+00	\N
61b0ab93-b097-498f-9039-df40420a4c91	d9598204-8b96-475e-b7b6-245a801d90bf	image	ocloudhub	nginx-proxy-manager	2.12.1)		failed				2026-04-28 14:33:12.796324+00	2026-04-28 14:33:12.813276+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:33:12Z" level=fatal msg="Invalid source name docker://[registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1](http://registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1): invalid reference format"\n	2026-04-28 14:33:12.796501+00	2026-04-28 14:33:12.813535+00	\N
f451aa5d-b48c-4bc4-9328-1b5929f87517	02a28976-b7ee-4a30-aa0d-719317cda8e6	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 14:57:12.237604+00	2026-04-28 14:57:14.439627+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:57:14Z" level=fatal msg="writing blob: initiating layer upload to /v2/ocloudhub/nginx-proxy-manager/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 14:57:12.237727+00	2026-04-28 14:57:14.439991+00	\N
8e558f86-6c4e-41b5-9172-fa3d39338e1e	378c753f-9d71-4553-9c0a-26ff0b5640a9	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 15:10:58.230937+00	2026-04-28 15:11:00.436528+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T15:11:00Z" level=fatal msg="writing blob: initiating layer upload to /v2/ocloudhub/nginx-proxy-manager/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 15:10:58.231038+00	2026-04-28 15:11:00.436866+00	\N
5f068ca7-563b-46da-b707-f0c28edc23af	ee8bf08f-a231-4f6e-9a28-f1a1e02eb558	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 19:09:43.569238+00	2026-04-28 19:10:21.564685+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T19:10:21Z" level=fatal msg="writing blob: determining upload URL: http: no Location header in response"\n	2026-04-28 19:09:43.569499+00	2026-04-28 19:10:21.565127+00	\N
04d14221-d66e-4216-a39a-16513132db01	aa0ab0f0-e30d-4b02-84eb-b8c402ac4b9b	image	ocloudhub	nginx-proxy-manager	2.12.1		failed				2026-04-28 21:43:43.395642+00	2026-04-28 21:44:20.635711+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T21:44:20Z" level=fatal msg="writing blob: uploading layer to http://registry-core:5000/v2/ocloudhub/nginx-proxy-manager/blobs/uploads/f0896b0e-baeb-4041-abbb-475406cc85e6?digest=sha256%3A302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab: StatusCode: 400, \\"\\""\n	2026-04-28 21:43:43.395763+00	2026-04-28 21:44:20.636117+00	\N
633393aa-eef6-4cbf-9232-27c00613ce62	3b7ff161-33b7-4a9d-beda-47f1f20960c8	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-28 22:11:59.323534+00	2026-04-28 22:12:37.44974+00	0		2026-04-28 22:11:59.323724+00	2026-04-28 22:12:37.462231+00	\N
cb4ec664-2084-43c8-93f1-826eecc565d4	b0bdc8cd-c6c7-4547-88c9-57f556320375	image	ocloudhub	nginx-proxy-manager	2.12.1)		failed				2026-04-28 23:33:50.748218+00	2026-04-28 23:33:50.775203+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T23:33:50Z" level=fatal msg="Invalid source name docker://[registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1](http://registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1): invalid reference format"\n	2026-04-28 23:33:50.748552+00	2026-04-28 23:33:50.775437+00	\N
fb86e93d-419c-4d04-a316-a32cfd482b81	8d4d39f1-8aef-498b-9e97-6d2eeb56f1c5	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-28 23:44:16.209965+00	2026-04-28 23:44:17.494352+00	0		2026-04-28 23:44:16.210078+00	2026-04-28 23:44:17.498388+00	\N
e2f2eb0f-52fa-4acd-b9f8-9d284b8d564e	a0794733-a23a-4f6f-9fdd-f3c2c2c4ee41	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-28 23:53:56.119874+00	2026-04-28 23:53:57.821866+00	0		2026-04-28 23:53:56.120137+00	2026-04-28 23:53:57.826046+00	\N
97eef704-2c4e-4443-9959-f9637e90f304	4790afac-71b2-457e-b58f-8272c008b61a	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 00:30:15.780163+00	2026-04-29 00:30:17.318364+00	0		2026-04-29 00:30:15.780301+00	2026-04-29 00:30:17.321504+00	\N
2b31d682-cf04-44ed-a365-c5e18b97810d	99561a51-95c3-44af-869c-46b74956172e	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 00:34:35.625526+00	2026-04-29 00:34:37.170865+00	0		2026-04-29 00:34:35.625928+00	2026-04-29 00:34:37.175525+00	\N
010a0e82-b36e-44b9-a36c-848179d907ea	c3edd977-872f-4816-80ea-d7826cb187d6	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 00:36:33.874781+00	2026-04-29 00:36:35.136357+00	0		2026-04-29 00:36:33.875161+00	2026-04-29 00:36:35.140228+00	\N
146e7f8c-a727-4490-bb9a-6261f3f7b0cb	b547ea3d-475f-4eb3-9a9b-1f6e7d670ba3	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 00:38:16.51442+00	2026-04-29 00:38:17.626461+00	0		2026-04-29 00:38:16.514885+00	2026-04-29 00:38:17.629548+00	\N
f0ee97e9-2dbc-483a-b6eb-a909e60b98e1	9d15aed7-8648-4904-9028-e9b5e74099b6	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 00:43:51.508127+00	2026-04-29 00:43:53.07927+00	0		2026-04-29 00:43:51.508499+00	2026-04-29 00:43:53.083449+00	\N
e7dcaf18-2a8d-43d5-ac75-100146704a2d	48c349a3-ae30-405d-a5eb-f9a416e3b319	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 00:46:36.481699+00	2026-04-29 00:46:37.759972+00	0		2026-04-29 00:46:36.482177+00	2026-04-29 00:46:37.762583+00	\N
22a06ecd-40c1-495f-bb22-716fd9931882	70c6f5e9-d0a3-4d34-9d6d-2241e441fa52	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 01:11:18.052106+00	2026-04-29 01:11:19.160609+00	0		2026-04-29 01:11:18.052246+00	2026-04-29 01:11:19.164417+00	\N
45a55141-9c8a-45a9-ad1c-0cbdf1cdfaff	25fc7df9-de4d-4572-9df3-e9ea89e98dce	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 01:11:53.667105+00	2026-04-29 01:11:54.688843+00	0		2026-04-29 01:11:53.667384+00	2026-04-29 01:11:54.691861+00	\N
110c2cd6-8bd2-4e42-875b-a5f89a23e883	edea844b-8054-4ae6-b799-d6a090e9c94b	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 01:23:59.411183+00	2026-04-29 01:24:00.563539+00	0	无效的镜像 digest: 	2026-04-29 01:23:59.411348+00	2026-04-29 01:24:00.563861+00	\N
98e7ecbf-423c-4451-9148-c2d2318cdc77	cbc71580-7468-4b99-bc4a-29dd5deb3d73	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 01:34:01.219756+00	2026-04-29 01:34:03.119346+00	0	无效的镜像 digest: 	2026-04-29 01:34:01.21988+00	2026-04-29 01:34:03.119675+00	\N
08839989-f4d0-4450-94c4-68d0b84fb828	764faff5-acb1-4bad-ab53-4330b830e2f3	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 01:40:19.641713+00	2026-04-29 01:40:20.957527+00	0	无效的镜像 digest: 	2026-04-29 01:40:19.641852+00	2026-04-29 01:40:20.957792+00	\N
b4bb47c4-7e97-4905-a448-61926863b550	1694ebc4-1894-416f-887d-2ae5b7522ffd	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 01:43:33.416131+00	2026-04-29 01:43:34.806113+00	0	无效的镜像 digest: 	2026-04-29 01:43:33.416415+00	2026-04-29 01:43:34.806398+00	\N
216fcc5f-9d0e-44ad-8233-d4e79a82a7b9	21770ba1-1302-4ce8-a8c2-52b7a6b4eb78	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 02:02:49.424272+00	2026-04-29 02:02:51.45095+00	0	无效的镜像 digest: 	2026-04-29 02:02:49.424419+00	2026-04-29 02:02:51.451249+00	\N
caab44aa-77f0-49e6-802c-36970a3f9ad4	6d238d52-e6d4-4f45-9cfd-a33e606766e8	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 02:18:27.914233+00	2026-04-29 02:18:29.263489+00	0	无效的镜像 digest: 	2026-04-29 02:18:27.914656+00	2026-04-29 02:18:29.263773+00	\N
7f87522c-8e5c-4300-9b3f-9b794ae3a59b	81465dd7-8528-42d0-acf9-3c099d4ed053	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 02:35:29.545635+00	2026-04-29 02:36:08.436841+00	0	无效的镜像 digest: 	2026-04-29 02:35:29.545867+00	2026-04-29 02:36:08.437122+00	\N
29e5a01c-eede-42d3-8dfe-4d2064bbabeb	d4046f0d-4f6b-4198-a402-a9f43f43611e	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 03:09:11.773907+00	2026-04-29 03:09:51.357049+00	0	无效的镜像 digest: 	2026-04-29 03:09:11.774247+00	2026-04-29 03:09:51.369202+00	\N
afa7fe7c-9131-4367-960b-bdc7078e4a1c	4c8ba686-a2fe-46c6-a796-8b15cf2ec8f9	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 03:26:01.82593+00	2026-04-29 03:26:03.386293+00	0	无效的镜像 digest: 	2026-04-29 03:26:01.826158+00	2026-04-29 03:26:03.386576+00	\N
bb699242-6799-4662-b9ab-d232214b78db	bbf1ecb9-d4c1-4bb4-be6c-12e99cf77b56	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 03:26:56.503086+00	2026-04-29 03:27:35.322377+00	0	无效的镜像 digest: 	2026-04-29 03:26:56.503535+00	2026-04-29 03:27:35.322724+00	\N
ea37d5e1-bd61-4437-859e-a5a968b9ee15	5bf6aafa-7a7f-4a46-9584-1b3a71e2e9fa	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 04:27:47.814938+00	2026-04-29 04:27:49.253043+00	0	无效的镜像 digest: 	2026-04-29 04:27:47.815213+00	2026-04-29 04:27:49.253194+00	\N
dc454b53-f07f-4d46-b616-251756fb8f41	b1641c44-0b5d-439e-b220-861bd98d0083	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 04:28:04.471225+00	2026-04-29 04:28:05.748558+00	0	无效的镜像 digest: 	2026-04-29 04:28:04.471537+00	2026-04-29 04:28:05.748722+00	\N
a4e28da1-dc4b-46ea-877d-50a617768e2c	4243c5b4-7ce8-459d-881c-d9af3e67fb47	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 04:28:18.406121+00	2026-04-29 04:28:56.855841+00	0	无效的镜像 digest: 	2026-04-29 04:28:18.406924+00	2026-04-29 04:28:56.855969+00	\N
6bdfb8cf-42e9-479f-bbf7-aff16d7aba00	0e50dcb0-4e4b-433e-854c-98561bd5becf	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 04:30:07.289514+00	2026-04-29 04:30:45.902227+00	0	无效的镜像 digest: 	2026-04-29 04:30:07.28974+00	2026-04-29 04:30:45.90237+00	\N
6df73054-29aa-4c6d-9bb5-435e63021525	bba55069-88fd-4ee0-b82d-5f50e210321f	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 04:35:13.017402+00	2026-04-29 04:35:52.34657+00	0	无效的镜像 digest: 	2026-04-29 04:35:13.01755+00	2026-04-29 04:35:52.346708+00	\N
d06d232e-3cdf-413e-895e-225b8362fc11	58457635-482c-42ab-9396-e8c7a89be984	image	ocloudhub	nginx-proxy-manager	2.12.1	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	success				2026-04-29 05:37:06.741714+00	2026-04-29 05:37:45.943262+00	0		2026-04-29 05:37:06.741844+00	2026-04-29 05:37:45.950379+00	\N
8654a976-769e-4884-beae-056b2df691b1	22a61120-d7ad-42c8-a075-b65f3421ea5f	image	ocloudhub	nginx-proxy-manager	2.12.1	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	success				2026-04-29 05:53:03.984832+00	2026-04-29 05:53:42.967732+00	0		2026-04-29 05:53:03.985198+00	2026-04-29 05:53:42.972369+00	\N
d69e9415-2d8e-4598-8663-6522655f246a	d735d637-8e3e-4854-849b-2f9483cd6f9d	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 09:10:55.131699+00	2026-04-29 09:10:56.801449+00	0	无效的镜像 digest: 	2026-04-29 09:10:55.13196+00	2026-04-29 09:10:56.801865+00	\N
b05f1441-accf-40ea-a8e8-15cbf60c7dd5	3daf7080-7a6b-47d2-a6df-f7ec373bcbf8	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 09:11:25.328578+00	2026-04-29 09:11:26.552538+00	0	无效的镜像 digest: 	2026-04-29 09:11:25.329465+00	2026-04-29 09:11:26.552726+00	\N
8c4a66bf-8bb4-4b8f-a70a-e497dcd932df	130d98ef-1835-44ff-8009-23d5d9438bc3	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 13:45:59.664054+00	2026-04-29 13:46:01.176576+00	0	无效的镜像 digest: 	2026-04-29 13:45:59.664314+00	2026-04-29 13:46:01.176799+00	\N
68df0228-bd90-4e77-9806-1c2a6dcc657c	3514f774-be45-4b2e-bb88-c4e25d7f6b3a	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 14:20:03.34758+00	2026-04-29 14:20:04.677109+00	0	无效的镜像 digest: 	2026-04-29 14:20:03.347963+00	2026-04-29 14:20:04.677305+00	\N
87f6158f-b924-421c-9247-f4b48ecf68f2	7a22305f-fd2f-4337-a61a-d41a9ae92711	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 14:37:46.642669+00	2026-04-29 14:37:48.11524+00	0	无效的镜像 digest: 	2026-04-29 14:37:46.64295+00	2026-04-29 14:37:48.115474+00	\N
231ebff9-fb6c-4be6-8ad5-a2e5ea517a5c	3e3295ca-a11f-4abf-a008-c1f60b5a5d2e	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 14:37:55.314894+00	2026-04-29 14:37:56.554742+00	0	无效的镜像 digest: 	2026-04-29 14:37:55.315271+00	2026-04-29 14:37:56.554881+00	\N
12699490-995d-48fd-b5b5-cb0899784a4a	cb725ed9-f249-4fb9-ad9d-570da90366f9	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 15:13:57.299731+00	2026-04-29 15:14:11.046555+00	0	无效的镜像 digest: 	2026-04-29 15:13:57.299891+00	2026-04-29 15:14:11.048078+00	\N
b6a67a60-84a8-4b2f-b68e-bcf74220a62a	4cebe8ea-f05e-4834-b995-9fc42e9996cd	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 15:14:22.430363+00	2026-04-29 15:14:36.144709+00	0	无效的镜像 digest: 	2026-04-29 15:14:22.43067+00	2026-04-29 15:14:36.146036+00	\N
90b8b59b-e301-460e-b32f-87f2f0a832cc	58356d52-4b81-46bc-8667-49cac5859bd0	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 15:19:12.798077+00	2026-04-29 15:19:26.488168+00	0	无效的镜像 digest: 	2026-04-29 15:19:12.798357+00	2026-04-29 15:19:26.489222+00	\N
18b241e3-5ed4-49e3-8ab3-837711f74ee1	f0c789a0-c5b1-4e34-b500-547e2d325a21	image	ocloudhub	nginx-proxy-manager	2.12.1		success				2026-04-29 15:30:43.533389+00	2026-04-29 15:30:56.873288+00	0	无效的镜像 digest: 	2026-04-29 15:30:43.53373+00	2026-04-29 15:30:56.874939+00	\N
1ba338e8-4973-45d9-ad88-bdd178d11e1b	7277226e-fd43-4218-8c6f-f87b6121e36e	image		hub.auok.online	50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27		failed				2026-04-29 15:32:13.183363+00	2026-04-29 15:32:13.208102+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-29T15:32:13Z" level=fatal msg="Invalid source name docker://https://hub.auok.online:50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27: invalid reference format"\n	2026-04-29 15:32:13.183711+00	2026-04-29 15:32:13.208213+00	\N
8410577e-886c-46da-8e44-6b5575091301	1e89c349-0a30-4a6e-a6bd-1999682209dd	image		hub.auok.online	50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27		failed				2026-04-29 15:32:17.601065+00	2026-04-29 15:32:17.621463+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-29T15:32:17Z" level=fatal msg="Invalid source name docker://https://hub.auok.online:50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27: invalid reference format"\n	2026-04-29 15:32:17.601316+00	2026-04-29 15:32:17.621741+00	\N
972b0337-f204-4b56-bcd7-a4a02fe2a727	26905660-f668-4b61-b4c0-ce79eebb71e9	image	ocloudhub	nginx-proxy-manager	2.12.1	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	success				2026-04-29 16:20:29.008853+00	2026-04-29 16:20:36.269845+00	0		2026-04-29 16:20:29.009201+00	2026-04-29 16:20:36.276076+00	\N
5d33f108-6336-46cf-92b5-50d61ff05848	53294a35-684e-47ca-8fb3-f83536574aed	image		hub.auok.online	50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27		failed				2026-04-29 16:26:00.61121+00	2026-04-29 16:26:00.645118+00	0	skopeo执行失败: exit status 1, stderr: time="2026-04-29T16:26:00Z" level=fatal msg="Invalid source name docker://https://hub.auok.online:50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27: invalid reference format"\n	2026-04-29 16:26:00.611529+00	2026-04-29 16:26:00.645303+00	\N
bb209610-83cb-46a8-90de-dcb8c3081f49	9e5d0360-dcbf-4fb8-bce1-cff52a142804	image	ocloudhub	nginx-proxy-manager	2.12.1	sha256:b88453c587ecafea4161fa3e7442a13ae84d7bdb50aa1c43a99826d75098e4fd	success				2026-04-29 16:26:23.479663+00	2026-04-29 16:26:31.160298+00	0		2026-04-29 16:26:23.480079+00	2026-04-29 16:26:31.167686+00	\N
e635ca90-b2a6-45dd-b295-548a39bb792b	1eec28df-76f8-4f3b-bb8f-a33c128ff951	image	ocloudhub	cloud-clipboard	latest	sha256:a18522803a50ed623d7e4f1ddbe04b9f423ce33a07f2c4ed46e11d47d100c5cd	success				2026-04-30 01:13:52.119533+00	2026-04-30 01:14:14.498233+00	0		2026-04-30 01:13:52.119994+00	2026-04-30 01:14:14.507251+00	\N
\.


--
-- Data for Name: replication_tasks; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.replication_tasks (id, policy_id, status, source_registry, dest_registry, started_at, ended_at, total_resources, succeeded_count, failed_count, skipped_count, error_message, created_at, updated_at, deleted_at, progress) FROM stdin;
1c035eca-66d2-4bc4-b687-b5f532d2b805	\N	failed	docker.io	local	2026-04-28 03:54:18.936191+00	2026-04-28 03:54:18.96574+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T03:54:18Z" level=fatal msg="Invalid destination name docker://http://registry-core:5000/library/nginx:latest: invalid reference format"\n	2026-04-28 03:54:18.926347+00	2026-04-28 03:54:19.051678+00	\N	0
407238c4-3952-40fb-b227-4a08e30f2cbc	\N	failed	docker.io	local	2026-04-28 03:57:36.253072+00	2026-04-28 03:59:43.378126+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T03:58:06Z" level=warning msg="Failed, retrying in 1s ... (1/3). Error: initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T03:58:37Z" level=warning msg="Failed, retrying in 2s ... (2/3). Error: initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T03:59:09Z" level=warning msg="Failed, retrying in 4s ... (3/3). Error: initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T03:59:43Z" level=fatal msg="initializing source docker://nginx:latest: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\n	2026-04-28 03:57:36.144083+00	2026-04-28 03:59:43.540774+00	\N	0
8c7eef6f-ccab-43f5-bc67-242bae624f3f	\N	failed	 registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 14:07:28.095416+00	2026-04-28 14:07:28.134863+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:07:28Z" level=fatal msg="Invalid source name docker:// registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1: invalid reference format"\n	2026-04-28 14:07:27.982458+00	2026-04-28 14:07:28.137113+00	\N	0
5c448849-d81c-437f-af7a-4065dd04f5e2	\N	failed	docker.io	local	2026-04-28 04:10:18.54982+00	2026-04-28 04:12:26.182919+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T04:10:48Z" level=warning msg="Failed, retrying in 1s ... (1/3). Error: initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T04:11:19Z" level=warning msg="Failed, retrying in 2s ... (2/3). Error: initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T04:11:51Z" level=warning msg="Failed, retrying in 4s ... (3/3). Error: initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\ntime="2026-04-28T04:12:26Z" level=fatal msg="initializing source docker://nginx:alpine: pinging container registry registry-1.docker.io: Get \\"https://registry-1.docker.io/v2/\\": dial tcp 192.133.77.191:443: i/o timeout"\n	2026-04-28 04:10:18.4502+00	2026-04-28 04:12:26.274385+00	\N	0
555f7fcf-2dda-4007-b02e-aaf39ee09610	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 08:30:04.842365+00	2026-04-28 08:30:05.51174+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T08:30:05Z" level=fatal msg="trying to reuse blob sha256:302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab at destination: pinging container registry registry-core:5000: Get \\"https://registry-core:5000/v2/\\": http: server gave HTTP response to HTTPS client"\n	2026-04-28 08:30:04.839254+00	2026-04-28 08:30:05.513997+00	\N	0
02a28976-b7ee-4a30-aa0d-719317cda8e6	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 14:57:12.234893+00	2026-04-28 14:57:14.439627+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:57:14Z" level=fatal msg="writing blob: initiating layer upload to /v2/ocloudhub/nginx-proxy-manager/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 14:57:12.152523+00	2026-04-28 14:57:14.44213+00	\N	0
2c651951-b5f9-493c-a1c1-e2b812538934	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 08:30:58.649392+00	2026-04-28 08:30:58.972194+00	1	0	1	0	skopeo执行失败: exit status 2, stderr: time="2026-04-28T08:30:58Z" level=fatal msg="initializing source docker://registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:latest: reading manifest latest in registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager: manifest unknown"\n	2026-04-28 08:30:58.645558+00	2026-04-28 08:30:58.975131+00	\N	0
c3df3de2-03ce-4305-a030-d60432692239	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 14:08:11.458254+00	2026-04-28 14:08:13.750403+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:08:13Z" level=fatal msg="writing blob: initiating layer upload to /v2/111/qwen3-coder-plus/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 14:08:11.437444+00	2026-04-28 14:08:13.752961+00	\N	0
4a2da474-2555-42ba-8a3e-904051979c5d	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 08:31:59.912361+00	2026-04-28 08:32:00.424836+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T08:32:00Z" level=fatal msg="trying to reuse blob sha256:302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab at destination: pinging container registry registry-core:5000: Get \\"https://registry-core:5000/v2/\\": http: server gave HTTP response to HTTPS client"\n	2026-04-28 08:31:59.909354+00	2026-04-28 08:32:00.453331+00	\N	0
17112487-784f-49fe-b349-3fd22823462c	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 08:42:38.27214+00	2026-04-28 08:42:41.179202+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T08:42:41Z" level=fatal msg="writing blob: uploading layer chunked: StatusCode: 404, \\"404 page not found\\""\n	2026-04-28 08:42:38.265068+00	2026-04-28 08:42:41.183712+00	\N	0
8a59841d-f39b-4126-a8f0-adfd58051ab2	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 11:47:47.257101+00	2026-04-28 11:47:49.72136+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T11:47:49Z" level=fatal msg="writing blob: initiating layer upload to /v2/ocloudhub/nginx-proxy-manager/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 11:47:47.253965+00	2026-04-28 11:47:49.725726+00	\N	0
d9598204-8b96-475e-b7b6-245a801d90bf	\N	failed	[registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 14:33:12.793871+00	2026-04-28 14:33:12.813276+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T14:33:12Z" level=fatal msg="Invalid source name docker://[registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1](http://registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1): invalid reference format"\n	2026-04-28 14:33:12.765397+00	2026-04-28 14:33:12.815483+00	\N	0
378c753f-9d71-4553-9c0a-26ff0b5640a9	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 15:10:58.228835+00	2026-04-28 15:11:00.436528+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T15:11:00Z" level=fatal msg="writing blob: initiating layer upload to /v2/ocloudhub/nginx-proxy-manager/blobs/uploads/ in registry-core:5000: StatusCode: 400, \\"\\""\n	2026-04-28 15:10:58.22615+00	2026-04-28 15:11:00.438934+00	\N	0
ee8bf08f-a231-4f6e-9a28-f1a1e02eb558	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 19:09:43.565154+00	2026-04-28 19:10:21.564685+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T19:10:21Z" level=fatal msg="writing blob: determining upload URL: http: no Location header in response"\n	2026-04-28 19:09:43.556838+00	2026-04-28 19:10:21.828208+00	\N	0
aa0ab0f0-e30d-4b02-84eb-b8c402ac4b9b	\N	failed	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 21:43:43.393814+00	2026-04-28 21:44:20.635711+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T21:44:20Z" level=fatal msg="writing blob: uploading layer to http://registry-core:5000/v2/ocloudhub/nginx-proxy-manager/blobs/uploads/f0896b0e-baeb-4041-abbb-475406cc85e6?digest=sha256%3A302e3ee498053a7b5332ac79e8efebec16e900289fc1ecd1c754ce8fa047fcab: StatusCode: 400, \\"\\""\n	2026-04-28 21:43:43.390615+00	2026-04-28 21:44:20.64073+00	\N	0
3b7ff161-33b7-4a9d-beda-47f1f20960c8	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 22:11:59.31965+00	2026-04-28 22:12:37.44974+00	1	1	0	0		2026-04-28 22:11:59.228488+00	2026-04-28 22:12:37.463785+00	\N	0
764faff5-acb1-4bad-ab53-4330b830e2f3	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 01:40:19.638049+00	2026-04-29 01:40:20.957527+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 01:40:19.633969+00	2026-04-29 01:40:20.959801+00	\N	0
b0bdc8cd-c6c7-4547-88c9-57f556320375	\N	failed	[registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 23:33:50.744034+00	2026-04-28 23:33:50.775203+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-28T23:33:50Z" level=fatal msg="Invalid source name docker://[registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1](http://registry.cn-hangzhou.aliyuncs.com/ocloudhub/nginx-proxy-manager:2.12.1): invalid reference format"\n	2026-04-28 23:33:50.737032+00	2026-04-28 23:33:50.777285+00	\N	0
8d4d39f1-8aef-498b-9e97-6d2eeb56f1c5	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 23:44:16.208189+00	2026-04-28 23:44:17.494352+00	1	1	0	0		2026-04-28 23:44:16.202169+00	2026-04-28 23:44:17.500101+00	\N	0
a0794733-a23a-4f6f-9fdd-f3c2c2c4ee41	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-28 23:53:56.116175+00	2026-04-28 23:53:57.821866+00	1	1	0	0		2026-04-28 23:53:56.1104+00	2026-04-28 23:53:57.827699+00	\N	0
1694ebc4-1894-416f-887d-2ae5b7522ffd	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 01:43:33.412306+00	2026-04-29 01:43:34.806113+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 01:43:33.405103+00	2026-04-29 01:43:34.808443+00	\N	0
4790afac-71b2-457e-b58f-8272c008b61a	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 00:30:15.77798+00	2026-04-29 00:30:17.318364+00	1	1	0	0		2026-04-29 00:30:15.775139+00	2026-04-29 00:30:17.323695+00	\N	0
99561a51-95c3-44af-869c-46b74956172e	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 00:34:35.621944+00	2026-04-29 00:34:37.170865+00	1	1	0	0		2026-04-29 00:34:35.610275+00	2026-04-29 00:34:37.177441+00	\N	0
c3edd977-872f-4816-80ea-d7826cb187d6	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 00:36:33.869661+00	2026-04-29 00:36:35.136357+00	1	1	0	0		2026-04-29 00:36:33.86435+00	2026-04-29 00:36:35.142937+00	\N	0
21770ba1-1302-4ce8-a8c2-52b7a6b4eb78	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 02:02:49.422091+00	2026-04-29 02:02:51.45095+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 02:02:49.398127+00	2026-04-29 02:02:51.454548+00	\N	0
b547ea3d-475f-4eb3-9a9b-1f6e7d670ba3	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 00:38:16.512354+00	2026-04-29 00:38:17.626461+00	1	1	0	0		2026-04-29 00:38:16.50849+00	2026-04-29 00:38:17.631727+00	\N	0
9d15aed7-8648-4904-9028-e9b5e74099b6	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 00:43:51.503661+00	2026-04-29 00:43:53.07927+00	1	1	0	0		2026-04-29 00:43:51.499334+00	2026-04-29 00:43:53.085314+00	\N	0
d735d637-8e3e-4854-849b-2f9483cd6f9d	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 09:10:55.127826+00	2026-04-29 09:10:56.801449+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 09:10:55.098284+00	2026-04-29 09:10:56.803859+00	\N	100
48c349a3-ae30-405d-a5eb-f9a416e3b319	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 00:46:36.476897+00	2026-04-29 00:46:37.759972+00	1	1	0	0		2026-04-29 00:46:36.44035+00	2026-04-29 00:46:37.765313+00	\N	0
6d238d52-e6d4-4f45-9cfd-a33e606766e8	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 02:18:27.909782+00	2026-04-29 02:18:29.263489+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 02:18:27.869417+00	2026-04-29 02:18:29.353669+00	\N	0
70c6f5e9-d0a3-4d34-9d6d-2241e441fa52	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 01:11:18.049994+00	2026-04-29 01:11:19.160609+00	1	1	0	0		2026-04-29 01:11:18.045553+00	2026-04-29 01:11:19.166548+00	\N	0
25fc7df9-de4d-4572-9df3-e9ea89e98dce	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 01:11:53.662765+00	2026-04-29 01:11:54.688843+00	1	1	0	0		2026-04-29 01:11:53.654367+00	2026-04-29 01:11:54.694271+00	\N	0
5bf6aafa-7a7f-4a46-9584-1b3a71e2e9fa	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 04:27:47.811491+00	2026-04-29 04:27:49.253043+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 04:27:47.793204+00	2026-04-29 04:27:49.255228+00	\N	100
edea844b-8054-4ae6-b799-d6a090e9c94b	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 01:23:59.408645+00	2026-04-29 01:24:00.563539+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 01:23:59.402299+00	2026-04-29 01:24:00.566205+00	\N	0
81465dd7-8528-42d0-acf9-3c099d4ed053	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 02:35:29.543214+00	2026-04-29 02:36:08.436841+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 02:35:29.538168+00	2026-04-29 02:36:08.438981+00	\N	0
cbc71580-7468-4b99-bc4a-29dd5deb3d73	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 01:34:01.217705+00	2026-04-29 01:34:03.119346+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 01:34:01.213245+00	2026-04-29 01:34:03.122384+00	\N	0
22a61120-d7ad-42c8-a075-b65f3421ea5f	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 05:53:03.981486+00	2026-04-29 05:53:42.967732+00	1	1	0	0		2026-04-29 05:53:03.888842+00	2026-04-29 05:53:42.974176+00	\N	100
d4046f0d-4f6b-4198-a402-a9f43f43611e	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 03:09:11.768214+00	2026-04-29 03:09:51.357049+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 03:09:11.71986+00	2026-04-29 03:09:51.371115+00	\N	0
0e50dcb0-4e4b-433e-854c-98561bd5becf	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 04:30:07.28745+00	2026-04-29 04:30:45.902227+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 04:30:07.273849+00	2026-04-29 04:30:45.904307+00	\N	100
4c8ba686-a2fe-46c6-a796-8b15cf2ec8f9	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 03:26:01.823151+00	2026-04-29 03:26:03.386293+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 03:26:01.697627+00	2026-04-29 03:26:03.390176+00	\N	0
bbf1ecb9-d4c1-4bb4-be6c-12e99cf77b56	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 03:26:56.498895+00	2026-04-29 03:27:35.322377+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 03:26:56.489342+00	2026-04-29 03:27:35.327213+00	\N	0
b1641c44-0b5d-439e-b220-861bd98d0083	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 04:28:04.466541+00	2026-04-29 04:28:05.748558+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 04:28:04.46191+00	2026-04-29 04:28:05.750745+00	\N	100
58457635-482c-42ab-9396-e8c7a89be984	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 05:37:06.739437+00	2026-04-29 05:37:45.943262+00	1	1	0	0		2026-04-29 05:37:06.733225+00	2026-04-29 05:37:45.953726+00	\N	100
4243c5b4-7ce8-459d-881c-d9af3e67fb47	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 04:28:18.29896+00	2026-04-29 04:28:56.855841+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 04:28:18.28512+00	2026-04-29 04:28:56.857712+00	\N	100
bba55069-88fd-4ee0-b82d-5f50e210321f	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 04:35:13.015107+00	2026-04-29 04:35:52.34657+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 04:35:13.001287+00	2026-04-29 04:35:52.348881+00	\N	100
3daf7080-7a6b-47d2-a6df-f7ec373bcbf8	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 09:11:25.220738+00	2026-04-29 09:11:26.552538+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 09:11:25.134267+00	2026-04-29 09:11:26.554765+00	\N	100
130d98ef-1835-44ff-8009-23d5d9438bc3	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 13:45:59.660065+00	2026-04-29 13:46:01.176576+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 13:45:59.652656+00	2026-04-29 13:46:01.178863+00	\N	100
3514f774-be45-4b2e-bb88-c4e25d7f6b3a	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 14:20:03.343238+00	2026-04-29 14:20:04.677109+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 14:20:03.33045+00	2026-04-29 14:20:04.679549+00	\N	100
7a22305f-fd2f-4337-a61a-d41a9ae92711	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 14:37:46.637579+00	2026-04-29 14:37:48.11524+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 14:37:46.632121+00	2026-04-29 14:37:48.117494+00	\N	100
3e3295ca-a11f-4abf-a008-c1f60b5a5d2e	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 14:37:55.309658+00	2026-04-29 14:37:56.554742+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 14:37:55.302917+00	2026-04-29 14:37:56.556862+00	\N	100
cb725ed9-f249-4fb9-ad9d-570da90366f9	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 15:13:57.295921+00	2026-04-29 15:14:11.046555+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 15:13:57.256522+00	2026-04-29 15:14:11.055376+00	\N	100
9e5d0360-dcbf-4fb8-bce1-cff52a142804	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 16:26:23.474692+00	2026-04-29 16:26:31.160298+00	1	1	0	0		2026-04-29 16:26:23.463506+00	2026-04-29 16:26:31.169925+00	\N	100
4cebe8ea-f05e-4834-b995-9fc42e9996cd	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 15:14:22.425541+00	2026-04-29 15:14:36.144709+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 15:14:22.420694+00	2026-04-29 15:14:36.153932+00	\N	100
58356d52-4b81-46bc-8667-49cac5859bd0	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 15:19:12.794168+00	2026-04-29 15:19:26.488168+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 15:19:12.778566+00	2026-04-29 15:19:26.494032+00	\N	100
1eec28df-76f8-4f3b-bb8f-a33c128ff951	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-30 01:13:52.115395+00	2026-04-30 01:14:14.498233+00	1	1	0	0		2026-04-30 01:13:52.109185+00	2026-04-30 01:14:14.510872+00	\N	100
6033becd-cd09-4be5-9acf-7e8470d512f7	19731ed5-cbd1-436e-8a9c-8953bec8c347	pending	111	local	2026-05-06 00:42:57.544927+00	\N	0	0	0	0		2026-05-06 00:42:57.545306+00	2026-05-06 00:42:57.545306+00	2026-05-06 00:43:33.149539+00	0
f0c789a0-c5b1-4e34-b500-547e2d325a21	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 15:30:43.529749+00	2026-04-29 15:30:56.873288+00	1	1	0	0	镜像复制成功但创建记录失败: 无效的镜像 digest: 	2026-04-29 15:30:43.521186+00	2026-04-29 15:30:56.935991+00	\N	100
7277226e-fd43-4218-8c6f-f87b6121e36e	\N	failed	https:	local	2026-04-29 15:32:13.179894+00	2026-04-29 15:32:13.208102+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-29T15:32:13Z" level=fatal msg="Invalid source name docker://https://hub.auok.online:50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27: invalid reference format"\n	2026-04-29 15:32:13.171107+00	2026-04-29 15:32:13.210216+00	\N	100
1e89c349-0a30-4a6e-a6bd-1999682209dd	\N	failed	https:	local	2026-04-29 15:32:17.595964+00	2026-04-29 15:32:17.621463+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-29T15:32:17Z" level=fatal msg="Invalid source name docker://https://hub.auok.online:50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27: invalid reference format"\n	2026-04-29 15:32:17.59057+00	2026-04-29 15:32:17.624559+00	\N	100
26905660-f668-4b61-b4c0-ce79eebb71e9	\N	success	registry.cn-hangzhou.aliyuncs.com	local	2026-04-29 16:20:29.004948+00	2026-04-29 16:20:36.269845+00	1	1	0	0		2026-04-29 16:20:28.998278+00	2026-04-29 16:20:36.278186+00	\N	100
53294a35-684e-47ca-8fb3-f83536574aed	\N	failed	https:	local	2026-04-29 16:26:00.607752+00	2026-04-29 16:26:00.645118+00	1	0	1	0	skopeo执行失败: exit status 1, stderr: time="2026-04-29T16:26:00Z" level=fatal msg="Invalid source name docker://https://hub.auok.online:50000/repositories/91f7c195-f1e7-47c2-958d-cd9547f9cf27: invalid reference format"\n	2026-04-29 16:26:00.598852+00	2026-04-29 16:26:00.647249+00	\N	100
\.


--
-- Data for Name: repositories; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.repositories (id, namespace_id, name, description, is_public, owner_id, pull_count, created_at, updated_at, deleted_at) FROM stdin;
8854a7bd-7f2d-47a6-bd19-6500b770b361	ee2b14ee-9975-4d5f-9668-2ed7a170181a	OpenClaw		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:04:30.873655+00	2026-04-30 05:04:30.873655+00	2026-04-30 06:22:52.280481+00
49f27f86-3493-48f9-874f-cb3a06013abd	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	2343647		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:04:19.065108+00	2026-04-30 05:04:19.065108+00	2026-04-30 06:22:53.932504+00
c32bef13-21fc-4bc1-bde9-14e9d67c5a02	1e9449d6-cda3-4bb2-a27b-75b7b5871ffb	jvv		t	5c894435-98c8-4ee3-8008-5c99311801fa	1	2026-04-29 01:42:57.965034+00	2026-04-29 01:43:53.201954+00	2026-04-29 01:49:02.828636+00
8bc3701e-0aba-4065-ac2c-b08e925aa10a	159aceae-b1ac-47f9-8f5a-3197e050c3bd	qwen3-coder		t	5c894435-98c8-4ee3-8008-5c99311801fa	1	2026-04-28 23:33:44.566198+00	2026-04-29 01:44:35.098748+00	2026-04-29 01:49:12.882095+00
b99d659a-bac1-4a21-ba62-03ff7b73e81c	8885854f-fce0-46c5-9185-a3319171dc27	qwen3-coder-plus		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-28 08:30:32.411662+00	2026-04-28 08:30:32.411662+00	2026-04-29 01:49:14.849611+00
6b8f0c98-d3e0-45cd-89be-920db1e51743	8885854f-fce0-46c5-9185-a3319171dc27	111	111	t	5c894435-98c8-4ee3-8008-5c99311801fa	3	2026-04-27 09:57:00.508786+00	2026-04-29 01:47:55.415572+00	2026-04-29 03:13:48.015063+00
f59f5184-9511-4fc4-9b56-b4f27a45dc97	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	234523536364		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:04:07.398491+00	2026-04-30 05:04:07.398491+00	2026-04-30 06:22:55.325279+00
997725f7-3cdf-4c7a-850d-f83d7beefbdd	38747182-f496-4ffa-988e-491c0e7d88c6	nginx-proxy-manager		t	\N	3	2026-04-28 22:12:37.428525+00	2026-04-29 03:15:47.280551+00	2026-04-29 04:30:02.185781+00
a02d62fe-fdb6-45ae-af75-15488f075a17	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	999999		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:06:05.840134+00	2026-04-30 05:06:05.840134+00	2026-04-30 05:20:35.812632+00
d3919651-c4d0-43d0-80ba-21a665ef863e	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	888888		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:06:01.027462+00	2026-04-30 05:06:01.027462+00	2026-04-30 05:20:43.63132+00
7fc7627b-8193-4f96-bd09-71b5d5f113b2	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	77777		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:05:56.613544+00	2026-04-30 05:05:56.613544+00	2026-04-30 05:20:45.444571+00
c0ee487b-ca03-4d12-8741-99820f76babd	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	1313213223414		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:05:52.092438+00	2026-04-30 05:05:52.092438+00	2026-04-30 05:20:46.967948+00
75aaeccf-c144-447b-9fd3-2793f52b51c8	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	547678586789696789		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:04:37.56309+00	2026-04-30 05:04:37.56309+00	2026-04-30 05:20:48.769132+00
807da1c5-c4c3-4893-865d-83b82243b0a9	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	56u		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:04:25.194427+00	2026-04-30 05:04:25.194427+00	2026-04-30 05:20:56.693247+00
55d7a861-8b42-4eea-8d22-20156723eb39	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	progress-test		t	\N	6	2026-04-29 04:30:45.851171+00	2026-04-29 14:31:56.917856+00	2026-05-06 00:40:32.199778+00
5972ec95-0837-44e0-94ca-1255665cd95e	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	22223124124		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:23:04.35376+00	2026-04-30 05:23:04.35376+00	2026-04-30 05:23:07.613288+00
e577e43b-c3d2-45aa-8c9b-741279c77905	a6c000df-936d-4c9a-9784-425bbd9aff31	11111		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:23:17.84908+00	2026-04-30 05:23:17.84908+00	2026-04-30 05:23:20.493692+00
3f88425d-e918-4cbe-b621-290ffbaba933	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	234325364346		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:04:02.543671+00	2026-04-30 05:04:02.543671+00	2026-04-30 06:23:07.664004+00
980228e6-bda3-4082-b29f-bc8646188a6b	0765d36a-dd9f-44ec-9cd8-80331c224851	asd		t	5c894435-98c8-4ee3-8008-5c99311801fa	3	2026-04-29 03:26:51.914083+00	2026-04-29 15:15:41.556543+00	2026-05-06 00:40:39.555174+00
c3947fb6-8653-4e84-b004-7cbed599c314	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	14235345345		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:03:53.863228+00	2026-04-30 05:03:53.863228+00	2026-04-30 06:23:09.703172+00
3b614046-d798-45a7-8dd0-25005d3ea6b6	ee2b14ee-9975-4d5f-9668-2ed7a170181a	111111111111111		t	5c894435-98c8-4ee3-8008-5c99311801fa	3	2026-04-29 03:08:38.126896+00	2026-04-29 03:25:36.727437+00	2026-04-29 16:43:08.495115+00
d32e0a68-8a9c-45d1-8764-c675fc050c46	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	complete-test		t	\N	0	2026-04-29 05:37:45.883222+00	2026-04-29 05:37:45.883222+00	2026-04-29 16:43:16.187569+00
56af2f86-fbc3-4d5d-9421-05665456eac8	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	123123123		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:03:49.2455+00	2026-04-30 05:03:49.2455+00	2026-04-30 06:23:11.719343+00
4d9baa84-ed73-4a48-9a0e-a84d9b6e401a	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	345346346		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 05:03:58.136903+00	2026-04-30 05:03:58.136903+00	2026-04-30 06:23:13.223827+00
83792091-93e0-4196-9f78-356d4f7856ee	f37b0062-4bf9-4031-9648-d22a09c120cc	hub11		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-05-01 14:41:52.454715+00	2026-05-01 14:41:52.454715+00	2026-05-06 00:39:36.339653+00
3451db2a-d95b-47a4-8d31-bc2adef13f32	0a6fb8f2-948f-4fd1-82e0-d9d8648e2802	ceshi1		f	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 10:09:06.759063+00	2026-04-30 10:09:06.759063+00	2026-05-06 00:39:29.799112+00
e9d3befb-9461-4d23-acf3-46333bd8d1ab	034ce41a-ca67-4c81-9187-f09f71d50836	hub1		f	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-05-01 14:40:45.599399+00	2026-05-01 14:40:45.599399+00	2026-05-06 00:39:32.024042+00
bebd3641-2aab-471c-8009-3db899bd1539	034ce41a-ca67-4c81-9187-f09f71d50836	hub2		f	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-05-01 14:40:54.512549+00	2026-05-01 14:41:12.715818+00	2026-05-06 00:39:34.167507+00
96152bb7-9010-44ac-9a6e-d276e7dbb392	f37b0062-4bf9-4031-9648-d22a09c120cc	hubhub2		f	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-05-01 14:42:04.245145+00	2026-05-01 14:42:04.245145+00	2026-05-06 00:39:38.071418+00
4e9df91c-6200-4670-ab6f-e1cb65baa58b	0bff377a-5520-4e8f-9393-5fd6be8ca3a2	hub1		t	178172f2-b066-43c6-9888-1f2a302d76b9	0	2026-05-01 14:43:35.969403+00	2026-05-01 14:43:35.969403+00	2026-05-06 00:39:39.773203+00
a98d75b4-0238-443b-b1fe-edc449440d47	0bff377a-5520-4e8f-9393-5fd6be8ca3a2	hub2		f	178172f2-b066-43c6-9888-1f2a302d76b9	0	2026-05-01 14:46:22.167706+00	2026-05-01 14:46:22.167706+00	2026-05-06 00:39:41.8637+00
39fea876-9f22-4a81-95df-9d1882613b15	ada962d3-835a-4d32-b311-fd9f2584b8dd	hub1		f	178172f2-b066-43c6-9888-1f2a302d76b9	0	2026-05-01 14:47:11.508111+00	2026-05-01 14:47:11.508111+00	2026-05-06 00:39:44.021431+00
1052dae5-7908-492c-b348-15f6e47a884d	ada962d3-835a-4d32-b311-fd9f2584b8dd	hub2		f	178172f2-b066-43c6-9888-1f2a302d76b9	0	2026-05-01 14:47:22.295884+00	2026-05-01 14:47:22.295884+00	2026-05-06 00:39:45.709888+00
7c375636-8bc3-4c47-a5c6-1655abb57d84	24d1ee66-b8a7-43ee-85da-c7a5c52fbdf7	ceshi		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 10:08:56.86922+00	2026-04-30 10:08:56.86922+00	2026-05-06 00:39:47.478408+00
0728f5ef-c6b4-432e-bb86-430e3afbf78a	0a6fb8f2-948f-4fd1-82e0-d9d8648e2802	123123124		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 06:30:55.42274+00	2026-04-30 06:30:55.42274+00	2026-05-06 00:39:49.529848+00
2ae0f805-b6d0-4bd6-9a8a-d6b3a4a20a9a	7c639c65-28d3-4c10-8dbe-619d5c49be88	11231		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-04-30 06:23:57.071463+00	2026-04-30 06:23:57.071463+00	2026-05-06 00:39:51.41402+00
73c9584c-640c-46d6-9fa7-e0596d7c76ae	bf96ab06-5b0e-4f53-a80f-f104b5cbbee4	22222222		t	5c894435-98c8-4ee3-8008-5c99311801fa	5	2026-04-29 05:52:51.80637+00	2026-04-29 14:36:24.304219+00	2026-05-06 00:40:09.7705+00
09b00111-4f5e-4d7e-93a8-5c0f13b9505a	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	final-test		t	\N	2	2026-04-29 04:35:52.301061+00	2026-04-29 14:30:27.043658+00	2026-05-06 00:40:22.648836+00
91f7c195-f1e7-47c2-958d-cd9547f9cf27	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	blob-test-2	这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事这事一个镜像镜像这事一个镜这事一个这事	f	\N	6	2026-04-29 02:36:08.391029+00	2026-04-30 05:36:07.946541+00	2026-05-06 00:41:25.824205+00
d15e9e85-a189-4759-a386-840ac511fd86	d3939621-c03c-4f4a-8d3f-05e9aad02cb9	redis		t	5c894435-98c8-4ee3-8008-5c99311801fa	1	2026-05-08 06:10:48.828248+00	2026-05-08 06:11:34.029231+00	2026-05-08 06:32:48.862396+00
4ea614ce-a986-4487-b62f-f4b66d0a9f09	d3939621-c03c-4f4a-8d3f-05e9aad02cb9	nginx		t	5c894435-98c8-4ee3-8008-5c99311801fa	3	2026-05-08 01:17:52.175192+00	2026-05-08 05:31:08.157704+00	2026-05-08 06:32:51.627495+00
58035b84-fa3c-4fa4-907a-591eda623b48	488702f2-5cd8-4a8f-a054-10c3a2926581	mysql		t	5c894435-98c8-4ee3-8008-5c99311801fa	0	2026-05-08 06:33:38.514153+00	2026-05-08 06:33:38.514153+00	\N
f96e7bab-f4a5-45cc-bbc7-f7b0d27b264d	488702f2-5cd8-4a8f-a054-10c3a2926581	redis		t	5c894435-98c8-4ee3-8008-5c99311801fa	1	2026-05-08 06:34:05.709514+00	2026-05-08 06:35:34.66891+00	\N
3e7fef21-8c67-4a8f-a026-cee770d974f5	7d5c8af3-f945-4eaf-82de-c87461bf0c32	222		t	5c894435-98c8-4ee3-8008-5c99311801fa	7	2026-05-07 02:41:22.771339+00	2026-05-08 04:23:36.194524+00	2026-05-08 04:24:53.921083+00
13c059d3-5090-4ebf-85c4-3a582584cea7	7c04b2b6-24f6-4d7f-9ef0-cfe67acd68ae	2222	这是一个镜像仓库简介部分	f	5c894435-98c8-4ee3-8008-5c99311801fa	12	2026-04-29 01:51:21.315381+00	2026-05-08 04:24:10.621339+00	2026-05-08 04:25:12.969545+00
31c7d765-af92-4f0a-855c-22fc9bc1aa82	d3939621-c03c-4f4a-8d3f-05e9aad02cb9	fastdfs		t	5c894435-98c8-4ee3-8008-5c99311801fa	7	2026-05-08 06:20:51.589679+00	2026-05-08 06:32:40.542118+00	2026-05-08 06:32:47.000397+00
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.tags (id, repository_id, name, manifest_id, pushed_by, pushed_at, created_at, updated_at, deleted_at) FROM stdin;
7d18af1b-2336-4331-b06e-1f3004a2203a	73c9584c-640c-46d6-9fa7-e0596d7c76ae	2.12.1	ac432b13-7bbc-4f92-b9d0-98b6a01a446f	replication	2026-04-29 05:53:42.969474+00	2026-04-29 05:53:42.924259+00	2026-04-29 05:53:42.969633+00	2026-05-06 00:40:04.476015+00
550ac4d0-ee5a-43fd-bca8-e89723e7e8a4	09b00111-4f5e-4d7e-93a8-5c0f13b9505a	2.12.1	b88153ba-de5d-4fd8-ba26-28a249a73efc	replication	2026-04-29 04:35:52.30724+00	2026-04-29 04:35:52.307456+00	2026-04-29 04:35:52.307456+00	2026-05-06 00:40:19.127893+00
81e7890f-2e74-484b-871c-3d2d7ac91ba4	55d7a861-8b42-4eea-8d22-20156723eb39	2.12.1	16b7e925-fba9-458f-b038-520b9703e024	replication	2026-04-29 04:30:45.867546+00	2026-04-29 04:30:45.867666+00	2026-04-29 04:30:45.867666+00	2026-05-06 00:40:26.874151+00
07dfb6f7-025f-405e-bf7e-e2b576d6fde2	980228e6-bda3-4082-b29f-bc8646188a6b	2.12.1	5468e998-e94d-445b-a5db-47e7e0b62a70	replication	2026-04-29 03:27:35.18456+00	2026-04-29 03:27:35.184778+00	2026-04-29 03:27:35.184778+00	2026-05-06 00:40:36.357632+00
df3d43e5-be42-498c-b6fb-ee7710a47227	91f7c195-f1e7-47c2-958d-cd9547f9cf27	2.12.1	f4e33578-4ee4-4915-8eb7-e47f2a8c02a7	replication	2026-04-29 16:26:31.164663+00	2026-04-29 16:26:25.040518+00	2026-04-29 16:26:31.164892+00	2026-05-06 00:41:21.521703+00
2a229c56-d1a5-4ac7-88fb-c7d4bad6f9b9	13c059d3-5090-4ebf-85c4-3a582584cea7	2.12.1	3ab094e7-a779-419f-8d39-65f61619bd73	replication	2026-04-29 16:20:36.273076+00	2026-04-29 02:02:51.42045+00	2026-04-29 16:20:36.273188+00	2026-05-08 04:24:15.223639+00
849ef378-a4b4-4b32-8d26-01f75a796fc7	13c059d3-5090-4ebf-85c4-3a582584cea7	latest	ec3efc3a-6d80-4dc1-a684-a0beab7280e6	replication	2026-04-30 01:14:14.502267+00	2026-04-30 01:14:08.367055+00	2026-04-30 01:14:14.502687+00	2026-05-08 04:24:17.157019+00
d9ab9ea2-8838-4ea9-99cb-7748e7fafc4f	13c059d3-5090-4ebf-85c4-3a582584cea7	1.0	84743dd8-49ab-4445-b556-5c8fca7c43b1	admin	2026-04-30 01:18:11.803951+00	2026-04-30 01:18:11.804461+00	2026-04-30 01:18:11.804461+00	2026-05-08 04:24:19.753106+00
9ec138ed-3b24-4309-bbf9-a7fec73b052c	13c059d3-5090-4ebf-85c4-3a582584cea7	alpine	834a77ee-725c-4362-8184-32ee3afdb3cd	replication	2026-05-06 10:58:30.199167+00	2026-05-06 10:58:30.199425+00	2026-05-06 10:58:30.199425+00	2026-05-08 04:24:21.771697+00
d11a0cfe-e1ab-41e7-acf6-19e7630c5010	3e7fef21-8c67-4a8f-a026-cee770d974f5	qqh9n	7d27368a-acbe-4287-9cef-d3b69a9dd061	jvv	2026-05-08 03:49:23.821512+00	2026-05-08 03:49:23.822023+00	2026-05-08 03:49:23.822023+00	2026-05-08 04:24:49.027758+00
82c06075-acff-403b-9237-ceac7a9ef46b	3e7fef21-8c67-4a8f-a026-cee770d974f5	1.0	af04d5e8-5b4a-4f23-b539-47f6452a0c1a	admin	2026-05-07 03:17:45.130232+00	2026-05-07 03:17:45.130541+00	2026-05-07 03:17:45.130541+00	2026-05-08 04:24:50.701556+00
feee2c16-b2cd-482e-97e7-6faefc4c0998	4ea614ce-a986-4487-b62f-f4b66d0a9f09	dar9o	5e0ee005-b11b-4265-88e6-e3e9f5a509b4	admin	2026-05-08 04:26:11.185651+00	2026-05-08 04:26:11.186102+00	2026-05-08 04:26:11.186102+00	2026-05-08 05:30:55.549384+00
00e8815f-ec79-48d0-ac1c-29bd914c4289	4ea614ce-a986-4487-b62f-f4b66d0a9f09	z22t3	0fc34bab-d312-41a1-8c05-117ab45343e6	replication	2026-05-08 05:32:20.519063+00	2026-05-08 05:32:20.519274+00	2026-05-08 05:32:20.519274+00	2026-05-08 05:39:05.947757+00
ce46424d-14db-424c-bf45-6d775ba64c07	4ea614ce-a986-4487-b62f-f4b66d0a9f09	b5h0m	08fff065-bd97-45b4-b867-ebc7c11afe21	replication	2026-05-08 05:30:46.189009+00	2026-05-08 05:30:46.189195+00	2026-05-08 05:30:46.189195+00	2026-05-08 05:39:07.88439+00
7a0df1d3-d3d8-4c2f-a22a-6558ecd2707f	c32bef13-21fc-4bc1-bde9-14e9d67c5a02	2.12.1	7633220e-2da0-4a1f-bd75-8c11454647c8	replication	2026-04-29 01:43:34.77834+00	2026-04-29 01:43:34.778522+00	2026-04-29 01:43:34.778522+00	2026-04-29 01:48:58.346522+00
fc61f494-96ba-4f33-99a9-e5bb532a2be0	8bc3701e-0aba-4065-ac2c-b08e925aa10a	2.12.1	5536cca5-bdf4-49d8-82c5-d4e853132470	replication	2026-04-29 01:40:20.928484+00	2026-04-29 01:40:20.928624+00	2026-04-29 01:40:20.928624+00	2026-04-29 01:49:09.135823+00
ec67a476-32f6-48de-a465-ab3fe1aae153	4ea614ce-a986-4487-b62f-f4b66d0a9f09	bpcis	37bb7054-018b-4e30-bef4-e8158bd85c27	admin	2026-05-08 05:40:52.339169+00	2026-05-08 05:40:52.336419+00	2026-05-08 05:40:52.339858+00	2026-05-08 06:12:45.391608+00
63d3ecee-6103-4411-9c6a-e067086a1633	d15e9e85-a189-4759-a386-840ac511fd86	n9ss7	66b30ea5-1b23-4f2a-b2ae-663c639321a0	admin	2026-05-08 06:11:23.738784+00	2026-05-08 06:11:23.736062+00	2026-05-08 06:11:23.739305+00	2026-05-08 06:20:38.574301+00
75eefa37-9f72-4627-9a31-bd72b30d4bfe	6b8f0c98-d3e0-45cd-89be-920db1e51743	latest	8efd4b80-c0f6-4782-a982-40f3d27309f9	admin	2026-04-27 09:58:55.239708+00	2026-04-27 09:58:55.241228+00	2026-04-27 09:58:55.241228+00	2026-04-29 03:13:39.789621+00
e399c2df-966f-4807-a398-cf8936e50c4d	6b8f0c98-d3e0-45cd-89be-920db1e51743	1	68e7e6a5-1263-481a-8b26-762399894d87	admin	2026-04-29 01:47:28.385056+00	2026-04-29 01:47:28.385303+00	2026-04-29 01:47:28.385303+00	2026-04-29 03:13:40.993234+00
9d9f6d24-a94f-44a6-af1d-ebedadf6f4ac	3b614046-d798-45a7-8dd0-25005d3ea6b6	2.12.1	2641b691-e55a-4ebc-b441-80a16d1151be	replication	2026-04-29 03:09:51.324973+00	2026-04-29 03:09:51.325076+00	2026-04-29 03:09:51.325076+00	2026-04-29 03:25:43.246125+00
793246ea-efc2-4124-aad9-0ce1d078aec7	31c7d765-af92-4f0a-855c-22fc9bc1aa82	m008d	092b3a8a-499c-4e41-b501-06259c807663	admin	2026-05-08 06:22:57.331103+00	2026-05-08 06:22:57.327489+00	2026-05-08 06:22:57.331807+00	2026-05-08 06:32:43.300552+00
de8601c7-e485-44e6-8fb0-783f9444379b	f96e7bab-f4a5-45cc-bbc7-f7b0d27b264d	7	88a232d8-da7d-4130-8cff-350cb1dc282d	admin	2026-05-08 06:34:45.840266+00	2026-05-08 06:34:45.836511+00	2026-05-08 06:34:45.841142+00	\N
3b4555d2-2fa3-486e-b4d4-655eb48033f8	997725f7-3cdf-4c7a-850d-f83d7beefbdd	2.12.1	fb202d3b-90e2-4da2-9acf-a15d9adc513a	replication	2026-04-28 22:12:37.45956+00	2026-04-28 22:12:37.439662+00	2026-04-28 22:12:37.459688+00	2026-04-29 04:29:51.771326+00
b5d3e3d2-8b43-4322-9162-fa53b0bc7edc	58035b84-fa3c-4fa4-907a-591eda623b48	5.7	cfe6c5e9-ccbc-4084-960c-142ebad3c7f5	admin	2026-05-08 06:36:05.296145+00	2026-05-08 06:36:05.290165+00	2026-05-08 06:36:05.29704+00	\N
63435e82-b471-4f41-8aa2-8b569dd06428	d32e0a68-8a9c-45d1-8764-c675fc050c46	2.12.1	8bcb40d4-14ed-4b88-96ce-766cc425eb77	replication	2026-04-29 05:37:45.945959+00	2026-04-29 05:37:45.88944+00	2026-04-29 05:37:45.946087+00	2026-04-29 09:11:10.337094+00
d9ac6d23-2846-4b3d-b8c3-95c8521ef889	13c059d3-5090-4ebf-85c4-3a582584cea7	1	ecf48bab-e6fc-4b20-8a37-387d19fb11cd	admin	2026-04-29 01:51:32.529454+00	2026-04-29 01:51:32.529566+00	2026-04-29 01:51:32.529566+00	2026-04-29 13:45:22.076306+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: registry
--

COPY public.users (id, username, password_hash, email, display_name, is_admin, is_active, last_login_at, created_at, updated_at, deleted_at) FROM stdin;
94e9ed02-1f17-458e-af18-00fc6e41938b	ceshi1	$2a$12$PG4BMyzUwfrmzgsJo/qmUOwRWCANayeSNUUS5.TWiTp1WcgUjpnrK			f	t	\N	2026-05-07 02:24:57.429515+00	2026-05-07 02:24:57.429515+00	\N
4c3c6ceb-acae-4a2b-b0c1-0bd86da363d4	1111	$2a$12$ELy0yZeYvVeJTtSg3K.w1uUO5L5wDpw4gKoA1zE.w29/bgtlKTvSq			f	t	\N	2026-05-07 02:27:29.836538+00	2026-05-07 02:27:29.836538+00	\N
367f2079-1d2e-4093-811a-0e023d94805b	222222	$2a$12$YnTcEBoGUjjYFmKTX/VchOMbQK2YPJQ3vQZTCI9IimKW.w/NUuLoe			f	t	\N	2026-05-07 02:27:38.05134+00	2026-05-07 02:27:38.05134+00	\N
c3efd9e1-a8ca-462b-9d87-08380aa4c53d	33333333	$2a$12$JMB0Q5j4ivQBjz5a1y8b/urQYTpYFloATuykNLEAehgPPDnTkMUvq			t	f	\N	2026-05-07 02:27:47.387024+00	2026-05-08 00:50:54.486997+00	\N
5c894435-98c8-4ee3-8008-5c99311801fa	admin	$2a$12$qL.kdTWDG84qghJIHNTkceUlchkZCBC/2YZl4Oqpetd.FAG/UECyK	admin@hub-registry.local	Administrator	t	t	2026-05-08 06:31:36.95461+00	2026-04-27 09:54:19.310477+00	2026-05-08 06:31:36.954904+00	\N
52238353-e4f1-4bd7-8894-3426b3b152ee	jvv	$2a$12$Ghn.0N3c2uVlvF6ADDsDjO58IxaXiVSCvvxnMuiNzlDLsUYz1d90a			f	t	2026-05-08 06:49:51.880823+00	2026-05-08 00:55:12.246611+00	2026-05-08 06:49:51.881162+00	\N
178172f2-b066-43c6-9888-1f2a302d76b9	test	$2a$12$f8CpLE5U4AGZDSdpYRlQDORteXR3zd8QSkkjdQvWwzmcWUTi5G7A.		teste	f	t	2026-05-01 14:42:24.336476+00	2026-04-30 05:54:32.589399+00	2026-05-06 10:13:28.446931+00	\N
\.


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: blobs blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.blobs
    ADD CONSTRAINT blobs_pkey PRIMARY KEY (id);


--
-- Name: manifest_blobs manifest_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.manifest_blobs
    ADD CONSTRAINT manifest_blobs_pkey PRIMARY KEY (blob_id, manifest_id);


--
-- Name: manifests manifests_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.manifests
    ADD CONSTRAINT manifests_pkey PRIMARY KEY (id);


--
-- Name: namespaces namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);


--
-- Name: registry_endpoints registry_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.registry_endpoints
    ADD CONSTRAINT registry_endpoints_pkey PRIMARY KEY (id);


--
-- Name: replication_policies replication_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.replication_policies
    ADD CONSTRAINT replication_policies_pkey PRIMARY KEY (id);


--
-- Name: replication_task_details replication_task_details_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.replication_task_details
    ADD CONSTRAINT replication_task_details_pkey PRIMARY KEY (id);


--
-- Name: replication_tasks replication_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.replication_tasks
    ADD CONSTRAINT replication_tasks_pkey PRIMARY KEY (id);


--
-- Name: repositories repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_resource_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_audit_logs_resource_id ON public.audit_logs USING btree (resource_id);


--
-- Name: idx_audit_logs_resource_type; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_audit_logs_resource_type ON public.audit_logs USING btree (resource_type);


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: idx_audit_logs_username; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_audit_logs_username ON public.audit_logs USING btree (username);


--
-- Name: idx_blobs_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_blobs_deleted_at ON public.blobs USING btree (deleted_at);


--
-- Name: idx_blobs_digest; Type: INDEX; Schema: public; Owner: registry
--

CREATE UNIQUE INDEX idx_blobs_digest ON public.blobs USING btree (digest);


--
-- Name: idx_manifests_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_manifests_deleted_at ON public.manifests USING btree (deleted_at);


--
-- Name: idx_manifests_repository_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_manifests_repository_id ON public.manifests USING btree (repository_id);


--
-- Name: idx_namespaces_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_namespaces_deleted_at ON public.namespaces USING btree (deleted_at);


--
-- Name: idx_namespaces_name; Type: INDEX; Schema: public; Owner: registry
--

CREATE UNIQUE INDEX idx_namespaces_name ON public.namespaces USING btree (name);


--
-- Name: idx_namespaces_owner_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_namespaces_owner_id ON public.namespaces USING btree (owner_id);


--
-- Name: idx_ns_repo; Type: INDEX; Schema: public; Owner: registry
--

CREATE UNIQUE INDEX idx_ns_repo ON public.repositories USING btree (namespace_id, name);


--
-- Name: idx_registry_endpoints_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_registry_endpoints_deleted_at ON public.registry_endpoints USING btree (deleted_at);


--
-- Name: idx_registry_endpoints_name; Type: INDEX; Schema: public; Owner: registry
--

CREATE UNIQUE INDEX idx_registry_endpoints_name ON public.registry_endpoints USING btree (name);


--
-- Name: idx_replication_policies_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_replication_policies_deleted_at ON public.replication_policies USING btree (deleted_at);


--
-- Name: idx_replication_task_details_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_replication_task_details_deleted_at ON public.replication_task_details USING btree (deleted_at);


--
-- Name: idx_replication_task_details_task_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_replication_task_details_task_id ON public.replication_task_details USING btree (task_id);


--
-- Name: idx_replication_tasks_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_replication_tasks_deleted_at ON public.replication_tasks USING btree (deleted_at);


--
-- Name: idx_replication_tasks_policy_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_replication_tasks_policy_id ON public.replication_tasks USING btree (policy_id);


--
-- Name: idx_repo_digest; Type: INDEX; Schema: public; Owner: registry
--

CREATE UNIQUE INDEX idx_repo_digest ON public.manifests USING btree (repository_id, digest);


--
-- Name: idx_repo_tag; Type: INDEX; Schema: public; Owner: registry
--

CREATE UNIQUE INDEX idx_repo_tag ON public.tags USING btree (repository_id, name);


--
-- Name: idx_repositories_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_repositories_deleted_at ON public.repositories USING btree (deleted_at);


--
-- Name: idx_repositories_owner_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_repositories_owner_id ON public.repositories USING btree (owner_id);


--
-- Name: idx_tags_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_tags_deleted_at ON public.tags USING btree (deleted_at);


--
-- Name: idx_tags_manifest_id; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_tags_manifest_id ON public.tags USING btree (manifest_id);


--
-- Name: idx_users_deleted_at; Type: INDEX; Schema: public; Owner: registry
--

CREATE INDEX idx_users_deleted_at ON public.users USING btree (deleted_at);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: registry
--

CREATE UNIQUE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: manifest_blobs fk_manifest_blobs_blob; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.manifest_blobs
    ADD CONSTRAINT fk_manifest_blobs_blob FOREIGN KEY (blob_id) REFERENCES public.blobs(id);


--
-- Name: manifest_blobs fk_manifest_blobs_manifest; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.manifest_blobs
    ADD CONSTRAINT fk_manifest_blobs_manifest FOREIGN KEY (manifest_id) REFERENCES public.manifests(id);


--
-- Name: manifests fk_manifests_repository; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.manifests
    ADD CONSTRAINT fk_manifests_repository FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: namespaces fk_namespaces_owner; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT fk_namespaces_owner FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: repositories fk_namespaces_repositories; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_namespaces_repositories FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: replication_task_details fk_replication_tasks_details; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.replication_task_details
    ADD CONSTRAINT fk_replication_tasks_details FOREIGN KEY (task_id) REFERENCES public.replication_tasks(id);


--
-- Name: replication_tasks fk_replication_tasks_policy; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.replication_tasks
    ADD CONSTRAINT fk_replication_tasks_policy FOREIGN KEY (policy_id) REFERENCES public.replication_policies(id);


--
-- Name: repositories fk_repositories_owner; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_repositories_owner FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: tags fk_repositories_tags; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_repositories_tags FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: tags fk_tags_manifest; Type: FK CONSTRAINT; Schema: public; Owner: registry
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_tags_manifest FOREIGN KEY (manifest_id) REFERENCES public.manifests(id);


--
-- PostgreSQL database dump complete
--

\unrestrict aZBllqFOU2l0NStFffiRTuA9mujQhNzqbmTRXyLEYqPPrgPL5FiJ3RxLdMbthPg

