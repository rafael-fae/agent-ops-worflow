# Django DRF SimpleJWT — Armadilhas de Configuração Cookie

> **Origem:** Auditoria task_19 (02/06/2026) — {{DEVOPS_ENGINEER}} implementou SimpleJWT com cookies HttpOnly.
> **Conclusão:** Configuração correta nos settings, mas views não entregavam cookies — 2 CRÍTICOS.

---

## Problema 1: `AUTH_COOKIE`/`AUTH_COOKIE_REFRESH` não setam cookies sozinhos

### O que o agente fez (errado)
```python
# config/settings/security.py
SIMPLE_JWT = {
    "AUTH_COOKIE": "access_token",
    "AUTH_COOKIE_REFRESH": "refresh_token",
    "AUTH_COOKIE_SECURE": True,
    "AUTH_COOKIE_HTTP_ONLY": True,
    "AUTH_COOKIE_SAMESITE": "Lax",
    ...
}
```
... e usou `TokenObtainPairView` padrão, que retorna JSON.

### Por que não funciona
- `TokenObtainPairView` padrão retorna `{"access": "...", "refresh": "..."}` no corpo JSON
- `JWTAuthentication` lê tokens do header `Authorization: Bearer` — **não de cookies**
- As settings `AUTH_COOKIE*` são **lidas apenas por `JWTCookieAuthentication`**, não por `JWTAuthentication`
- O settings declara a intenção, mas a view não age sobre ela

### Correção necessária
```python
# Opção A: Sobrescrever a view para setar cookie manualmente
class TenantTokenObtainPairView(TokenObtainPairView):
    serializer_class = TenantTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            refresh_token = response.data.pop("refresh")  # remove do JSON
            response.set_cookie(
                key="refresh_token",
                value=refresh_token,
                max_age=7 * 24 * 3600,  # 7 dias
                httponly=True,
                secure=True,
                samesite="Lax",
                path="/api/auth/",
            )
        return response

# Opção B: Usar JWTCookieAuthentication em vez de JWTAuthentication
# (mas perde compatibilidade com Bearer header para access token)
```

---

## Problema 2: `TokenRefreshSerializer` padrão não preserva claims customizadas

### O que o agente fez (errado)
```python
# config/urls.py
path("api/auth/refresh/", TokenRefreshView.as_view(), name="jwt-refresh"),
```
`TokenRefreshView` usa `TokenRefreshSerializer` padrão.

### Por que não funciona
O `TokenRefreshSerializer` padrão do SimpleJWT **não copia claims customizadas** do refresh token original para os novos tokens. Claims como `tenant_db` e `clinica_id` são perdidas.

### Correção necessária
```python
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken

class TenantTokenRefreshSerializer(TokenRefreshSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        refresh = RefreshToken(attrs["refresh"])

        # Preservar claims de tenant do refresh original
        new_refresh = RefreshToken.for_user(refresh.user)
        for claim in ("tenant_db", "clinica_id"):
            if claim in refresh:
                new_refresh[claim] = refresh[claim]

        data["access"] = str(new_refresh.access_token)
        data["refresh"] = str(new_refresh)
        return data

# urls.py
path("api/auth/refresh/", TokenRefreshView.as_view(
    serializer_class=TenantTokenRefreshSerializer
), name="jwt-refresh"),
```

---

## Problema 3: `AUTH_COOKIE="access_token"` conflita com "access em memória"

O requisito era: access token em memória (Bearer header), refresh em cookie. Mas:
```python
"AUTH_COOKIE": "access_token",       # ← conflitante
"AUTH_COOKIE_REFRESH": "refresh_token",  # ← correto
```
Se `JWTCookieAuthentication` fosse usado, o access token também seria enviado como cookie — violando o requisito.

**Correção:** Remover `AUTH_COOKIE` ou setar como `None`. Manter apenas `AUTH_COOKIE_REFRESH`.

---

## Problema 4 (Sutil): Claims perdidas na 2ª rotação do refresh

### Cenário
Após corrigir o Problema 2 (criar `TenantTokenRefreshSerializer`), o agente injetou claims apenas no **access token**, não no **refresh token** rotacionado.

### Por que falha só na 2ª rotação
1. **1º refresh**: Extrai `tenant_db`/`clinica_id` do refresh original → injeta no access ✅
2. O novo refresh token (gerado por `ROTATE_REFRESH_TOKENS=True`) NÃO recebe as claims
3. **2º refresh**: Tenta extrair claims do refresh... que não as tem mais ❌

### Sintoma
- Após ~14 dias (2 ciclos de 7 dias), o contexto multi-tenant desaparece
- `TenantJWTAuthentication` cai no fallback de headers (`X-Oeste-Tenant-DB`/`X-Clinic-ID`)
- Se o cliente não envia headers, perde acesso ao tenant

### Correção completa
```python
class TenantTokenRefreshSerializer(TokenRefreshSerializer):
    def validate(self, attrs):
        # 1. Extrai claims do refresh original ANTES da rotação
        old_refresh = RefreshToken(attrs["refresh"])
        tenant_db = old_refresh.get("tenant_db")
        clinica_id = old_refresh.get("clinica_id")

        # 2. Validação padrão (rotação, blacklist)
        data = super().validate(attrs)

        # 3. Injeta claims no NOVO access token
        if tenant_db or clinica_id is not None:
            new_refresh = RefreshToken(data["refresh"]) if "refresh" in data else old_refresh
            access = new_refresh.access_token
            if tenant_db:
                access["tenant_db"] = tenant_db
            if clinica_id is not None:
                access["clinica_id"] = clinica_id
            data["access"] = str(access)

            # 4. CRÍTICO: injeta claims também no NOVO refresh token
            #    Sem isto, a 2ª rotação perde as claims.
            if "refresh" in data:
                if tenant_db:
                    new_refresh["tenant_db"] = tenant_db
                if clinica_id is not None:
                    new_refresh["clinica_id"] = clinica_id
                data["refresh"] = str(new_refresh)

        return data
```

> **Regra de ouro:** Claims customizadas precisam ser injetadas em **ambos** os tokens gerados na rotação — access E refresh. Injetar só no access adia o bug em 1 ciclo.

---

## Checklist de Auditoria para JWT + Cookies

Ao auditar implementação SimpleJWT com cookies:

- [ ] `AUTH_COOKIE` está `None` se access token deve ficar em memória?
- [ ] `AUTH_COOKIE_REFRESH` está configurado com nome do cookie?
- [ ] A authentication class em `DEFAULT_AUTHENTICATION_CLASSES` é compatível com o modo de entrega? (`JWTAuthentication` = header, `JWTCookieAuthentication` = cookie)
- [ ] A view de login sobrescreve `post()` para setar o cookie no response? Ou usa view nativa que seta cookies?
- [ ] A view de refresh preserva claims customizadas (`tenant_db`, etc)?
- [ ] `TokenBlacklistView` tem `rest_framework_simplejwt.token_blacklist` em `INSTALLED_APPS`?
- [ ] Claims customizadas (`tenant_db`, `clinica_id`) são injetadas tanto no **access** QUANTO no **refresh** durante a rotação? (Ver Problema 4 — 2ª rotação)
- [ ] Rodar `python3 manage.py check` após as correções
