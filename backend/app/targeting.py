import json
import zlib
from typing import Dict, Any, Optional

def evaluate_targeting_rule(flag: Any, context: Optional[Dict[str, Any]]) -> bool:
    """
    Evaluates targeting rules for a FeatureFlag against a user context dictionary.
    
    Rules support:
    - everyone: returns flag.is_enabled directly.
    - group: returns flag.is_enabled if context['group'] matches rule's parameter.
    - rollout: returns flag.is_enabled if zlib.crc32(context['id'].encode()) % 100 < rollout_percentage.
    """
    if context is None:
        context = {}
        
    rule = getattr(flag, "targeting_rule", None)
    if rule is None:
        return flag.is_enabled
        
    if isinstance(rule, str):
        try:
            rule = json.loads(rule)
        except Exception:
            rule = {"type": "everyone"}
            
    if not isinstance(rule, dict):
        rule = {"type": "everyone"}
        
    rule_type = rule.get("type", "everyone")
    parameter = rule.get("parameter")
    
    if rule_type == "everyone":
        return flag.is_enabled
        
    elif rule_type == "group":
        client_group = context.get("group")
        if client_group is not None and str(client_group) == str(parameter):
            return flag.is_enabled
        return False
        
    elif rule_type == "rollout":
        if not parameter:
            return False
        try:
            pct_str = "".join(filter(str.isdigit, str(parameter)))
            percentage = int(pct_str) if pct_str else 0
        except (ValueError, TypeError):
            return False
            
        user_id = context.get("id") or context.get("user_id")
        if user_id is None:
            return False
            
        user_id_str = str(user_id)
        user_hash = zlib.crc32(user_id_str.encode("utf-8")) % 100
        
        if user_hash < percentage:
            return flag.is_enabled
        return False
        
    return flag.is_enabled
