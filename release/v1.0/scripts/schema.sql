--
-- PostgreSQL database dump
--

\restrict RoiK18AHg4cWflOQiQJXJ8pVUV7So4WobIKcbdvkDIHWVy6WfesbSAlAOZTRbGH

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

\unrestrict RoiK18AHg4cWflOQiQJXJ8pVUV7So4WobIKcbdvkDIHWVy6WfesbSAlAOZTRbGH

