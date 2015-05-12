-module(octo_repo_contents).
-include("octo.hrl").
-export([
  %list/3, read/4, list_commits/4, list_files/4, is_merged/4, create/4, update/5, merge/4
  get_archive_link/5
]).

%% API

get_archive_link(Owner, Repo, Format, Ref, Options) ->
  Url          = octo_url_helper:get_archive_link(Owner, Repo, Format, Ref),
  {ok, Result} = octo_http_helper:get_headers(Url, Options),
  {ok, Result}.
  %%{ok, ?json_to_record(octo_pull_request, Result)}.
