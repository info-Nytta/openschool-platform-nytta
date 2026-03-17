import logging

import httpx

logger = logging.getLogger(__name__)


def invite_user_to_org(username: str, org: str, admin_token: str) -> bool:
    """Invite a GitHub user to the organization. Returns True if successful or already a member."""
    try:
        response = httpx.put(
            f"https://api.github.com/orgs/{org}/memberships/{username}",
            headers={
                "Authorization": f"Bearer {admin_token}",
                "Accept": "application/vnd.github+json",
            },
            json={"role": "member"},
            timeout=10.0,
        )
        if response.status_code in (200, 201):
            logger.info("Invited %s to %s", username, org)
            return True
        logger.warning("Org invite failed for %s: %s", username, response.status_code)
        return False
    except httpx.HTTPError:
        logger.exception("Org invite error for %s", username)
        return False


async def check_exercise_status(owner: str, repo_name: str, github_token: str) -> bool:
    """Check if the latest CI workflow run in the repo was successful."""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"https://api.github.com/repos/{owner}/{repo_name}/actions/runs",
                headers={"Authorization": f"Bearer {github_token}"},
                params={"per_page": 1, "status": "completed"},
            )
            if response.status_code != 200:
                return False
            runs = response.json().get("workflow_runs", [])
            if not runs:
                return False
            return runs[0]["conclusion"] == "success"
    except httpx.TimeoutException:
        logger.warning("GitHub API timeout for %s/%s", owner, repo_name)
        return False
    except httpx.HTTPError:
        logger.exception("GitHub API error for %s/%s", owner, repo_name)
        return False
