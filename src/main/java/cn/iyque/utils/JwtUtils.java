package cn.iyque.utils;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.function.Function;

public class JwtUtils {
    /**
     * 上游把密钥硬编码在源码里并公开在 GitHub 上，任何人都能对任意源雀部署伪造管理员 token。
     * 改为优先读环境变量 IYQUE_JWT_SECRET / 系统属性 iyque.jwt-secret，
     * 都没有时才回退到上游默认值（仅供本地开发；生产必须覆盖）。
     * 注意：签名算法为 HS384，密钥长度必须 >= 48 字节。
     */
    private static final String SECRET_KEY = resolveSecret();

    private static String resolveSecret() {
        String s = System.getenv("IYQUE_JWT_SECRET");
        if (s == null || s.trim().isEmpty()) {
            s = System.getProperty("iyque.jwt-secret");
        }
        if (s == null || s.trim().isEmpty()) {
            return "iYqueSecretKeyForJwtTokenGenerationAndValidation";
        }
        if (s.getBytes(java.nio.charset.StandardCharsets.UTF_8).length < 48) {
            throw new IllegalStateException("IYQUE_JWT_SECRET 长度不足 48 字节，HS384 要求密钥 >= 384 bit");
        }
        return s;
    }
    private static final long EXPIRATION_TIME = 7 * 24 * 60 * 60 * 1000;

    private static SecretKey getSigningKey() {
        byte[] keyBytes = SECRET_KEY.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public static String generateToken(String username) {
        return Jwts.builder()
                .subject(username)
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(getSigningKey())
                .compact();
    }

    public static String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    public static Date getExpirationDateFromToken(String token) {
        return getClaimFromToken(token, Claims::getExpiration);
    }

    public static <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        Claims claims = getAllClaimsFromToken(token);
        return claimsResolver.apply(claims);
    }

    private static Claims getAllClaimsFromToken(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public static Boolean isTokenExpired(String token) {
        Date expiration = getExpirationDateFromToken(token);
        return expiration.before(new Date());
    }

    public static Boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
