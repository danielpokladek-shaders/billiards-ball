using UnityEngine;

public class PoolBall : MonoBehaviour
{
    [Header("References")]
    [SerializeField]
    Renderer _renderer;

    [Header("Ball Properties")]
    [SerializeField]
    bool _hasStripe;

    [SerializeField]
    Color _stripeColor;

    [SerializeField]
    [Range(0, 15)]
    int _number;

    private Material _material;

    private void Start()
    {
        _material = _renderer.material;
        _material.SetColor("_Accent_Color", _stripeColor);
        _material.SetInt("_Has_Line", _hasStripe ? 1 : 0);
        _material.SetInt("_Number", _number);

        transform.rotation = Random.rotation;
    }
}
